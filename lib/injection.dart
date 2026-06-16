import 'package:get_it/get_it.dart';
import 'package:ludo_game/domain/game_repository.dart';
import 'package:ludo_game/data/game_repository_impl.dart';
import 'package:ludo_game/presentation/bloc/game_bloc.dart';
import 'package:ludo_game/presentation/bloc/online_game_bloc.dart';
import 'package:ludo_game/core/services/firebase_service.dart';

final getIt = GetIt.instance;

void setupDependencyInjection() {
  // Services
  getIt.registerLazySingleton<FirebaseService>(
    () => FirebaseService(),
  );

  // Repositories
  getIt.registerLazySingleton<GameRepository>(
    () => GameRepositoryImpl(),
  );

  // BLoCs
  getIt.registerFactory(
    () => GameBloc(gameRepository: getIt()),
  );
  getIt.registerFactory(
    () => OnlineGameBloc(gameRepository: getIt()),
  );
}