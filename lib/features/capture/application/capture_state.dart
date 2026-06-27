import 'package:catdex/features/capture/domain/entities/captured_photo.dart';

enum CaptureStatus {
  idle,
  requestingPermission,
  picking,
  selected,
  invalid,
  failure,
}

class CaptureState {
  const CaptureState({
    required this.status,
    this.photo,
    this.message,
  });

  const CaptureState.idle()
    : status = CaptureStatus.idle,
      photo = null,
      message = null;

  final CaptureStatus status;
  final CapturedPhoto? photo;
  final String? message;

  bool get canContinue => status == CaptureStatus.selected && photo != null;

  CaptureState copyWith({
    CaptureStatus? status,
    CapturedPhoto? photo,
    String? message,
    bool clearPhoto = false,
    bool clearMessage = false,
  }) {
    return CaptureState(
      status: status ?? this.status,
      photo: clearPhoto ? null : photo ?? this.photo,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
