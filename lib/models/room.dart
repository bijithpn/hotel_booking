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
    // Status pattern for Floor 1 (25 rooms) — matches mockup color spread
    const floor1Statuses = [
      RoomStatus.available,    // 101
      RoomStatus.occupied,     // 102
      RoomStatus.occupied,     // 103
      RoomStatus.dirty,        // 104
      RoomStatus.dirty,        // 105
      RoomStatus.maintenance,  // 106
      RoomStatus.maintenance,  // 107
      RoomStatus.available,    // 108
      RoomStatus.available,    // 109
      RoomStatus.occupied,     // 110
      RoomStatus.available,    // 111
      RoomStatus.available,    // 112
      RoomStatus.available,    // 113
      RoomStatus.available,    // 114
      RoomStatus.available,    // 115
      RoomStatus.available,    // 116
      RoomStatus.blocked,      // 117
      RoomStatus.available,    // 118
      RoomStatus.dirty,        // 119
      RoomStatus.maintenance,  // 120
      RoomStatus.available,    // 121
      RoomStatus.available,    // 122
      RoomStatus.occupied,     // 123
      RoomStatus.available,    // 124
      RoomStatus.available,    // 125
    ];

    // Status pattern for Floor 2 (25 rooms)
    const floor2Statuses = [
      RoomStatus.available,    // 201
      RoomStatus.occupied,     // 202
      RoomStatus.dirty,        // 203
      RoomStatus.available,    // 204
      RoomStatus.maintenance,  // 205
      RoomStatus.available,    // 206
      RoomStatus.available,    // 207
      RoomStatus.blocked,      // 208
      RoomStatus.available,    // 209
      RoomStatus.occupied,     // 210
      RoomStatus.available,    // 211
      RoomStatus.available,    // 212
      RoomStatus.available,    // 213
      RoomStatus.available,    // 214
      RoomStatus.available,    // 215
      RoomStatus.dirty,        // 216
      RoomStatus.available,    // 217
      RoomStatus.available,    // 218
      RoomStatus.maintenance,  // 219
      RoomStatus.occupied,     // 220
      RoomStatus.available,    // 221
      RoomStatus.available,    // 222
      RoomStatus.available,    // 223
      RoomStatus.blocked,      // 224
      RoomStatus.available,    // 225
    ];

    final rooms = <Room>[];

    for (int i = 0; i < 25; i++) {
      final num = 101 + i;
      rooms.add(Room(
        code: 'R$num',
        type: _typeFor(num),
        pricePerNight: _priceFor(num),
        maxGuests: _maxGuestsFor(num),
        status: floor1Statuses[i],
        floor: 1,
        number: num,
      ));
    }

    for (int i = 0; i < 25; i++) {
      final num = 201 + i;
      rooms.add(Room(
        code: 'R$num',
        type: _typeFor(num),
        pricePerNight: _priceFor(num),
        maxGuests: _maxGuestsFor(num),
        status: floor2Statuses[i],
        floor: 2,
        number: num,
      ));
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
