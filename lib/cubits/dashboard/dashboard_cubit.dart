import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/room.dart';
import 'dashboard_state.dart';

export 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(DashboardState.initial());

  void reloadRooms() {
    emit(state.copyWith(rooms: List<Room>.from(Room.allRooms)));
  }

  void setRoomStatus(Room room, RoomStatus status) {
    room.status = status;
    emit(state.copyWith(rooms: List<Room>.from(state.rooms)));
  }

  void setAllDirtyToAvailable() {
    for (final r in state.rooms) {
      if (r.status == RoomStatus.dirty) r.status = RoomStatus.available;
    }
    emit(state.copyWith(rooms: List<Room>.from(state.rooms)));
  }

  void selectQuickRoom(Room? room) {
    if (room == null) {
      emit(state.copyWith(clearSelectedQuickRoom: true));
    } else {
      emit(state.copyWith(selectedQuickRoom: room));
    }
  }

  /// Marks the currently selected quick room as available and clears the
  /// selection. Returns the room that was updated, or null if none selected.
  Room? completeQuickCleaning() {
    final room = state.selectedQuickRoom;
    if (room == null) return null;
    setRoomStatus(room, RoomStatus.available);
    emit(state.copyWith(clearSelectedQuickRoom: true));
    return room;
  }
}
