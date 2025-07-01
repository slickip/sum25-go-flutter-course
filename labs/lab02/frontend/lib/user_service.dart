class UserService {
  Future<Map<String, String>> fetchUser() async {
    await Future.delayed(const Duration(seconds: 1));
    // Возвращаем данные пользователя
    return {
      'name': 'John CENA',
      'email': 'johnCENA@gmail.com',
    };
  }

  Future<void> updateUser(Map<String, String> updatedData) async {
    // Симулируем задержку обновления
    await Future.delayed(const Duration(milliseconds: 500));
    // Здесь можно добавить проверку или исключение
    if (updatedData['name']?.isEmpty ?? true) {
      throw UnimplementedError();
    }
  }
}
