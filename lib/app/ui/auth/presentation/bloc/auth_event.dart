import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class SignInWithGoogleRequested extends AuthEvent {}

class SignInWithGmailRequested extends AuthEvent {
  final String email;
  SignInWithGmailRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class SignOutRequested extends AuthEvent {}

class DeleteAccountRequested extends AuthEvent {}
