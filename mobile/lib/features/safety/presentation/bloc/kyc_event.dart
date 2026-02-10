import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class KycEvent extends Equatable {
  const KycEvent();

  @override
  List<Object?> get props => [];
}

class KycStatusLoadRequested extends KycEvent {
  const KycStatusLoadRequested();
}

class KycFrontImageSelected extends KycEvent {
  final File image;

  const KycFrontImageSelected(this.image);

  @override
  List<Object?> get props => [image.path];
}

class KycBackImageSelected extends KycEvent {
  final File image;

  const KycBackImageSelected(this.image);

  @override
  List<Object?> get props => [image.path];
}

class KycSelfieSelected extends KycEvent {
  final File image;

  const KycSelfieSelected(this.image);

  @override
  List<Object?> get props => [image.path];
}

class KycSubmitRequested extends KycEvent {
  const KycSubmitRequested();
}

class KycStepChanged extends KycEvent {
  final int step;

  const KycStepChanged(this.step);

  @override
  List<Object?> get props => [step];
}
