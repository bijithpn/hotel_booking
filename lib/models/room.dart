enum RoomStatus { available, occupied, dirty, maintenance, blocked }

class Room {
  final String code;
  final String type;
  final int pricePerNight;
  final int maxGuests;
  RoomStatus status;
  final int floor;
  final int number;

  Room({
    required this.code,
    required this.type,
    required this.pricePerNight,
    required this.maxGuests,
    required this.status,
    required this.floor,
    required this.number,
  });

  static final List<Room> allRooms = _buildRooms();

  static List<Room> _buildRooms() {
    const floor1Statuses = [
      RoomStatus.available,
      RoomStatus.occupied,
      RoomStatus.occupied,
      RoomStatus.dirty,
      RoomStatus.dirty,
      RoomStatus.maintenance,
      RoomStatus.maintenance,
      RoomStatus.available,
      RoomStatus.available,
      RoomStatus.occupied,
      RoomStatus.available,
      RoomStatus.available,
      RoomStatus.available,
      RoomStatus.available,
      RoomStatus.available,
      RoomStatus.available,
      RoomStatus.blocked,
      RoomStatus.available,
      RoomStatus.dirty,
      RoomStatus.maintenance,
      RoomStatus.available,
      RoomStatus.available,
      RoomStatus.occupied,
      RoomStatus.available,
      RoomStatus.available,
    ];

    const floor2Statuses = [
      RoomStatus.available,
      RoomStatus.occupied,
      RoomStatus.dirty,
      RoomStatus.available,
      RoomStatus.maintenance,
      RoomStatus.available,
      RoomStatus.available,
      RoomStatus.blocked,
      RoomStatus.available,
      RoomStatus.occupied,
      RoomStatus.available,
      RoomStatus.available,
      RoomStatus.available,
      RoomStatus.available,
      RoomStatus.available,
      RoomStatus.dirty,
      RoomStatus.available,
      RoomStatus.available,
      RoomStatus.maintenance,
      RoomStatus.occupied,
      RoomStatus.available,
      RoomStatus.available,
      RoomStatus.available,
      RoomStatus.blocked,
      RoomStatus.available,
    ];

    final rooms = <Room>[];

    for (int i = 0; i < 25; i++) {
      final num = 101 + i;
      rooms.add(
        Room(
          code: 'R$num',
          type: _typeFor(num),
          pricePerNight: _priceFor(num),
          maxGuests: _maxGuestsFor(num),
          status: floor1Statuses[i],
          floor: 1,
          number: num,
        ),
      );
    }

    for (int i = 0; i < 25; i++) {
      final num = 201 + i;
      rooms.add(
        Room(
          code: 'R$num',
          type: _typeFor(num),
          pricePerNight: _priceFor(num),
          maxGuests: _maxGuestsFor(num),
          status: floor2Statuses[i],
          floor: 2,
          number: num,
        ),
      );
    }

    return rooms;
  }

  static String _typeFor(int num) {
    final n = num % 10;
    if (n == 3 || n == 4) return 'Executive Suite';
    if (n == 5 || n == 6) return 'Family Room';
    return 'Deluxe Room';
  }

  static int _priceFor(int num) {
    final n = num % 10;
    if (n == 3 || n == 4) return 5800;
    if (n == 5 || n == 6) return 4200;
    return 3500;
  }

  static int _maxGuestsFor(int num) {
    final n = num % 10;
    if (n == 3 || n == 4) return 3;
    if (n == 5 || n == 6) return 4;
    return 2;
  }
}
