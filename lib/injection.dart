import 'package:get_it/get_it.dart';
import 'package:ludo_game/domain/game_repository.dart';
import 'package:ludo_game/data/game_repository_impl.dart';
import 'package:ludo_game/presentation/bloc/game_bloc.dart';

final getIt = GetIt.instance;

void setupDependencyInjection() {
  // Repositories
  getIt.registerLazySingleton<GameRepository>(
    () => GameRepositoryImpl(),
  );

  // BLoCs
  getIt.registerFactory(
    () => GameBloc(gameRepository: getIt()),
  );
}