import 'package:equatable/equatable.dart';
import '../../models/room.dart';

class DashboardState extends Equatable {
  final List<Room> rooms;
  final Room? selectedQuickRoom;

  const DashboardState({required this.rooms, this.selectedQuickRoom});

  factory DashboardState.initial() =>
      DashboardState(rooms: List<Room>.from(Room.allRooms));

  DashboardState copyWith({
    List<Room>? rooms,
    Room? selectedQuickRoom,
    bool clearSelectedQuickRoom = false,
  }) {
    return DashboardState(
      rooms: rooms ?? this.rooms,
      selectedQuickRoom: clearSelectedQuickRoom
          ? null
          : (selectedQuickRoom ?? this.selectedQuickRoom),
    );
  }

  @override
  List<Object?> get props => [rooms, selectedQuickRoom];
}
