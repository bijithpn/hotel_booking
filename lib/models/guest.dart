class Guest {
  final String id;
  final String name;
  final String phone;

  const Guest({required this.id, required this.name, required this.phone});

  @override
  String toString() => '$name — $phone';

  static final List<Guest> mockGuests = [
    Guest(id: 'G001', name: 'Mathew Hyden', phone: '9876543210'),
    Guest(id: 'G002', name: 'Sarah Thompson', phone: '9876543211'),
    Guest(id: 'G003', name: 'James Smith', phone: '9876543212'),
    Guest(id: 'G004', name: 'Emily Clark', phone: '9876543213'),
    Guest(id: 'G005', name: 'Michael Brown', phone: '9876543214'),
    Guest(id: 'G006', name: 'Jessica Lee', phone: '9876543215'),
    Guest(id: 'G007', name: 'David Wilson', phone: '9876543216'),
    Guest(id: 'G008', name: 'Sophia Martinez', phone: '9876543217'),
  ];
}
