import '../domain/user_model.dart';
import '../../../core/contracts/i_storage_service.dart';

class AuthRepository {
  final IStorageService _storageService;

  AuthRepository(this._storageService);

  static const List<User> demoUsers = [
    User(
      id: 'USR-001',
      fullName: 'Carlos Mendoza',
      email: 'carlos.mendoza@asisgo.com',
      role: 'Ingeniero de Software Senior',
      documentNumber: '72384910',
      assignedBranchId: 'BR-01',
      shiftStartTime: '08:30',
      shiftEndTime: '18:00',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    ),
    User(
      id: 'USR-002',
      fullName: 'Mariana Ruiz',
      email: 'mariana.ruiz@asisgo.com',
      role: 'Especialista de RRHH & Talento',
      documentNumber: '45892314',
      assignedBranchId: 'BR-02',
      shiftStartTime: '09:00',
      shiftEndTime: '18:30',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    ),
  ];

  Future<User?> getCurrentUser() async {
    final session = _storageService.getUserSession();
    if (session != null) {
      return User.fromJson(session);
    }
    return null;
  }

  Future<User> loginWithCredentials({required String email, required String password}) async {
    // Simula peticion de red
    await Future.delayed(const Duration(milliseconds: 600));
    final found = demoUsers.firstWhere(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => demoUsers.first,
    );
    await _storageService.saveUserSession(found.toJson());
    return found;
  }

  Future<User> loginWithBiometrics() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final defaultUser = demoUsers.first;
    await _storageService.saveUserSession(defaultUser.toJson());
    return defaultUser;
  }

  Future<void> logout() async {
    await _storageService.clearUserSession();
  }
}
