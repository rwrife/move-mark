import 'package:flutter_test/flutter_test.dart';
import 'package:move_mark/move_domain.dart';

final stamp = DateTime.utc(2026, 11, 12, 12);

void main() {
  DestinationRoom room(String id) => DestinationRoom(id: id, name: 'Kitchen');
  Carton carton(int number, {String roomId = 'kitchen'}) => Carton(
    number: number,
    title: 'Box $number',
    items: ['Plates', 'Cups'],
    destinationRoomId: roomId,
    priority: CartonPriority.essential,
    fragile: true,
  );
  Move move({List<Carton>? cartons}) => Move(
    id: 'm1',
    name: 'Apartment move',
    rooms: [room('kitchen')],
    cartons: cartons ?? [carton(1)],
  );

  test('constructs all four pure domain types and exposes immutable data', () {
    final source = ['Plates'];
    final box = Carton(
      number: 1,
      title: 'Box',
      items: source,
      destinationRoomId: 'kitchen',
      priority: CartonPriority.high,
      fragile: true,
    );
    source.add('Hidden');
    expect(box.items, ['Plates']);
    expect(() => box.items.add('Hidden'), throwsUnsupportedError);
    expect(box.status, CartonStatus.packed);
    expect(box.events, isEmpty);
    expect(CartonStatus.values, [
      CartonStatus.packed,
      CartonStatus.loaded,
      CartonStatus.inTransit,
      CartonStatus.delivered,
      CartonStatus.opened,
      CartonStatus.reconciled,
    ]);
    expect(CartonPriority.values, [
      CartonPriority.essential,
      CartonPriority.high,
      CartonPriority.normal,
      CartonPriority.low,
    ]);
    expect(() => move().cartons.clear(), throwsUnsupportedError);
    expect(() => move().rooms.clear(), throwsUnsupportedError);
  });

  test('records timestamped transitions and supports reversing check-off', () {
    final original = move();
    final delivered = original.transitionCarton(
      1,
      CartonStatus.delivered,
      stamp,
    );
    final opened = delivered.transitionCarton(
      1,
      CartonStatus.opened,
      stamp.add(const Duration(seconds: 1)),
    );
    final reversed = opened.transitionCarton(
      1,
      CartonStatus.delivered,
      stamp.add(const Duration(seconds: 2)),
    );
    expect(original.cartons.single.status, CartonStatus.packed);
    expect(reversed.cartons.single.events, [
      CartonEvent(
        from: CartonStatus.packed,
        to: CartonStatus.delivered,
        at: stamp,
      ),
      CartonEvent(
        from: CartonStatus.delivered,
        to: CartonStatus.opened,
        at: stamp.add(const Duration(seconds: 1)),
      ),
      CartonEvent(
        from: CartonStatus.opened,
        to: CartonStatus.delivered,
        at: stamp.add(const Duration(seconds: 2)),
      ),
    ]);
    expect(reversed.cartons.single.status, CartonStatus.delivered);
    expect(
      () => reversed.cartons.single.events.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => reversed.transitionCarton(1, CartonStatus.delivered, stamp),
      throwsArgumentError,
    );
    expect(
      () => reversed.transitionCarton(1, CartonStatus.opened, stamp),
      throwsArgumentError,
    );
    expect(
      () => reversed.transitionCarton(9, CartonStatus.opened, stamp),
      throwsArgumentError,
    );
    expect(
      () => original.transitionCarton(1, CartonStatus.opened, DateTime(2026)),
      throwsArgumentError,
    );
  });

  test('tracks reconciled completion independently of delivered count', () {
    final base = move(cartons: [carton(1), carton(2), carton(3)]);
    expect(base.completion.total, 3);
    expect(base.completion.reconciled, 0);
    expect(base.completion.isComplete, false);
    final arrived = base.transitionCarton(1, CartonStatus.delivered, stamp);
    expect(arrived.completion.deliveredOrLater, 1);
    expect(arrived.completion.reconciled, 0);
    final finished = arrived
        .transitionCarton(
          1,
          CartonStatus.reconciled,
          stamp.add(const Duration(seconds: 1)),
        )
        .transitionCarton(2, CartonStatus.reconciled, stamp)
        .transitionCarton(3, CartonStatus.reconciled, stamp);
    expect(finished.completion.reconciled, 3);
    expect(finished.completion.isComplete, true);
    expect(Move(id: 'empty', name: 'Empty').completion.isComplete, false);
  });

  test('rejects invalid names, duplicate room IDs and carton numbers', () {
    expect(() => Move(id: '', name: 'Moving'), throwsArgumentError);
    expect(() => Move(id: 'm', name: '   '), throwsArgumentError);
    expect(() => DestinationRoom(id: '', name: 'A'), throwsArgumentError);
    expect(() => DestinationRoom(id: 'r', name: ' '), throwsArgumentError);
    expect(
      () => Carton(number: 0, title: 'B', destinationRoomId: 'r'),
      throwsArgumentError,
    );
    expect(
      () => Carton(number: 1, title: ' ', destinationRoomId: 'r'),
      throwsArgumentError,
    );
    expect(
      () => Carton(number: 1, title: 'B', destinationRoomId: ''),
      throwsArgumentError,
    );
    expect(
      () => Carton(number: 1, title: 'B', destinationRoomId: 'r', items: [' ']),
      throwsArgumentError,
    );
    expect(
      () => Move(id: 'm', name: 'M', rooms: [room('r'), room('r')]),
      throwsArgumentError,
    );
    expect(() => move(cartons: [carton(1), carton(1)]), throwsArgumentError);
    expect(
      () => move(cartons: [carton(1, roomId: 'missing')]),
      throwsArgumentError,
    );
  });

  test('rejects forged, out-of-order and local-time history', () {
    expect(
      () => CartonEvent(
        from: CartonStatus.packed,
        to: CartonStatus.packed,
        at: stamp,
      ),
      throwsArgumentError,
    );
    expect(
      () => CartonEvent(
        from: CartonStatus.packed,
        to: CartonStatus.loaded,
        at: DateTime(2026),
      ),
      throwsArgumentError,
    );
    expect(
      CartonEvent(
        from: CartonStatus.packed,
        to: CartonStatus.loaded,
        at: stamp,
      ),
      CartonEvent(
        from: CartonStatus.packed,
        to: CartonStatus.loaded,
        at: stamp,
      ),
    );
    expect(
      CartonEvent(
        from: CartonStatus.packed,
        to: CartonStatus.loaded,
        at: stamp,
      ).hashCode,
      CartonEvent(
        from: CartonStatus.packed,
        to: CartonStatus.loaded,
        at: stamp,
      ).hashCode,
    );
    final stats = MoveCompletionStats.calculate([
      Carton(
        number: 1,
        title: 'A',
        destinationRoomId: 'r',
        status: CartonStatus.loaded,
        events: [
          CartonEvent(
            from: CartonStatus.packed,
            to: CartonStatus.loaded,
            at: stamp,
          ),
        ],
      ),
      Carton(
        number: 2,
        title: 'B',
        destinationRoomId: 'r',
        status: CartonStatus.inTransit,
        events: [
          CartonEvent(
            from: CartonStatus.packed,
            to: CartonStatus.inTransit,
            at: stamp,
          ),
        ],
      ),
      Carton(
        number: 3,
        title: 'C',
        destinationRoomId: 'r',
        status: CartonStatus.opened,
        events: [
          CartonEvent(
            from: CartonStatus.packed,
            to: CartonStatus.opened,
            at: stamp,
          ),
        ],
      ),
    ]);
    expect(stats.loaded, 1);
    expect(stats.inTransit, 1);
    expect(stats.opened, 1);
    expect(stats.percentReconciled, 0.0);
    expect(Move(id: 'm', name: 'M').completion.percentReconciled, 0.0);
    expect(
      () => Carton(
        number: 1,
        title: 'Box',
        destinationRoomId: 'r',
        status: CartonStatus.opened,
      ),
      throwsArgumentError,
    );
    final valid = CartonEvent(
      from: CartonStatus.packed,
      to: CartonStatus.loaded,
      at: stamp,
    );
    expect(
      () => Carton(
        number: 1,
        title: 'Box',
        destinationRoomId: 'r',
        status: CartonStatus.opened,
        events: [valid],
      ),
      throwsArgumentError,
    );
    expect(
      () => Carton(
        number: 1,
        title: 'Box',
        destinationRoomId: 'r',
        status: CartonStatus.loaded,
        events: [valid, valid],
      ),
      throwsArgumentError,
    );
  });
}
