// Pure Dart domain models for Move Mark: no UI, no database, no Flutter.

enum CartonStatus { packed, loaded, inTransit, delivered, opened, reconciled }

enum CartonPriority { essential, high, normal, low }

class DestinationRoom {
  DestinationRoom({required this.id, required this.name}) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Room id must not be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Room name must not be empty');
    }
  }

  final String id;
  final String name;
}

class CartonEvent {
  CartonEvent({
    required this.from,
    required this.to,
    required this.at,
    this.note,
  }) {
    if (from == to) {
      throw ArgumentError('CartonEvent transition must change status ($from)');
    }
    if (!at.isUtc) {
      throw ArgumentError.value(at, 'at', 'CartonEvent timestamp must be UTC');
    }
  }

  final CartonStatus from;
  final CartonStatus to;
  final DateTime at;
  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartonEvent &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to &&
          at == other.at &&
          note == other.note;

  @override
  int get hashCode => Object.hash(from, to, at, note);
}

class Carton {
  Carton({
    required this.number,
    required this.title,
    required this.destinationRoomId,
    List<String> items = const [],
    this.priority = CartonPriority.normal,
    this.fragile = false,
    this.status = CartonStatus.packed,
    List<CartonEvent> events = const [],
  }) : items = List.unmodifiable(_validateItems(items)),
       events = List.unmodifiable(events) {
    if (number <= 0) {
      throw ArgumentError.value(
        number,
        'number',
        'Carton number must be positive',
      );
    }
    if (title.trim().isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'Carton title must not be empty',
      );
    }
    if (destinationRoomId.trim().isEmpty) {
      throw ArgumentError.value(
        destinationRoomId,
        'destinationRoomId',
        'Destination room must not be empty',
      );
    }
    _validateEvents(status, events);
  }

  static List<String> _validateItems(List<String> raw) {
    for (final item in raw) {
      if (item.trim().isEmpty) {
        throw ArgumentError('Item description must not be blank');
      }
    }
    return raw;
  }

  static void _validateEvents(CartonStatus current, List<CartonEvent> events) {
    if (events.isEmpty) {
      if (current != CartonStatus.packed) {
        throw ArgumentError(
          'Carton with non-packed status ($current) must include history events',
        );
      }
      return;
    }
    CartonStatus expected = CartonStatus.packed;
    DateTime? lastStamp;
    for (final event in events) {
      if (event.from != expected) {
        throw ArgumentError(
          'Broken history: expected from $expected but got ${event.from}',
        );
      }
      if (lastStamp != null && !event.at.isAfter(lastStamp)) {
        throw ArgumentError(
          'Carton events must be strictly ascending: ${event.at} not after $lastStamp',
        );
      }
      expected = event.to;
      lastStamp = event.at;
    }
    if (expected != current) {
      throw ArgumentError(
        'Carton status $current does not match final event target $expected',
      );
    }
  }

  final int number;
  final String title;
  final List<String> items;
  final String destinationRoomId;
  final CartonPriority priority;
  final bool fragile;
  final CartonStatus status;
  final List<CartonEvent> events;

  Carton transitionTo(CartonStatus target, DateTime timestamp, {String? note}) {
    if (target == status) {
      throw ArgumentError('Carton $number is already in status $target');
    }
    final event = CartonEvent(
      from: status,
      to: target,
      at: timestamp,
      note: note,
    );
    final nextEvents = <CartonEvent>[...events, event];
    return Carton(
      number: number,
      title: title,
      items: items,
      destinationRoomId: destinationRoomId,
      priority: priority,
      fragile: fragile,
      status: target,
      events: nextEvents,
    );
  }
}

class MoveCompletionStats {
  const MoveCompletionStats({
    required this.total,
    required this.packed,
    required this.loaded,
    required this.inTransit,
    required this.delivered,
    required this.opened,
    required this.reconciled,
  });

  factory MoveCompletionStats.calculate(Iterable<Carton> cartons) {
    int total = 0;
    int packed = 0;
    int loaded = 0;
    int inTransit = 0;
    int delivered = 0;
    int opened = 0;
    int reconciled = 0;
    for (final c in cartons) {
      total++;
      switch (c.status) {
        case CartonStatus.packed:
          packed++;
          break;
        case CartonStatus.loaded:
          loaded++;
          break;
        case CartonStatus.inTransit:
          inTransit++;
          break;
        case CartonStatus.delivered:
          delivered++;
          break;
        case CartonStatus.opened:
          opened++;
          break;
        case CartonStatus.reconciled:
          reconciled++;
          break;
      }
    }
    return MoveCompletionStats(
      total: total,
      packed: packed,
      loaded: loaded,
      inTransit: inTransit,
      delivered: delivered,
      opened: opened,
      reconciled: reconciled,
    );
  }

  final int total;
  final int packed;
  final int loaded;
  final int inTransit;
  final int delivered;
  final int opened;
  final int reconciled;

  int get deliveredOrLater => delivered + opened + reconciled;

  bool get isComplete => total > 0 && reconciled == total;

  double get percentReconciled =>
      total == 0 ? 0.0 : (reconciled / total) * 100.0;
}

class Move {
  Move({
    required this.id,
    required this.name,
    List<DestinationRoom> rooms = const [],
    List<Carton> cartons = const [],
  }) : rooms = List.unmodifiable(rooms),
       cartons = List.unmodifiable(cartons) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Move id must not be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Move name must not be empty');
    }
    final roomIds = <String>{};
    for (final r in rooms) {
      if (!roomIds.add(r.id)) {
        throw ArgumentError('Duplicate room ID ${r.id} in move $id');
      }
    }
    final cartonNumbers = <int>{};
    for (final c in cartons) {
      if (!cartonNumbers.add(c.number)) {
        throw ArgumentError(
          'Duplicate carton number ${c.number} within move $id',
        );
      }
      if (!roomIds.contains(c.destinationRoomId)) {
        throw ArgumentError(
          'Carton ${c.number} destination room ${c.destinationRoomId} not found in move rooms',
        );
      }
    }
  }

  final String id;
  final String name;
  final List<DestinationRoom> rooms;
  final List<Carton> cartons;

  MoveCompletionStats get completion => MoveCompletionStats.calculate(cartons);

  Move transitionCarton(
    int number,
    CartonStatus target,
    DateTime timestamp, {
    String? note,
  }) {
    final index = cartons.indexWhere((c) => c.number == number);
    if (index < 0) {
      throw ArgumentError('Carton number $number does not exist in move $id');
    }
    final updated = cartons[index].transitionTo(target, timestamp, note: note);
    final nextCartons = [...cartons]..[index] = updated;
    return Move(id: id, name: name, rooms: rooms, cartons: nextCartons);
  }
}
