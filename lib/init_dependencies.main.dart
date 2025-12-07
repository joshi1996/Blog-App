part of 'init_dependencies.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  // -------------------------------------------
  // 1. Initialize Supabase FIRST
  // -------------------------------------------
  final supabase = await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseAnonKey,
  );

  serviceLocator.registerLazySingleton<SupabaseClient>(() => supabase.client);

  // -------------------------------------------
  // 2. Initialize Hive BEFORE any data source uses Hive
  // -------------------------------------------
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  await Hive.openBox('blogs');

  serviceLocator.registerSingleton<Box>(Hive.box('blogs'));

  // -------------------------------------------
  // 3. Core
  // -------------------------------------------
  serviceLocator.registerFactory<InternetConnection>(
    () => InternetConnection(),
  );

  serviceLocator.registerFactory<ConnectionChecker>(
    () => ConnectionCheckerImpl(serviceLocator()),
  );

  serviceLocator.registerLazySingleton<AppUserCubit>(() => AppUserCubit());

  // -------------------------------------------
  // 4. Now initialize modules (everything needed is ready)
  // -------------------------------------------
  _initAuth();
  _initBlog();
}

// =======================================================
//                     AUTH MODULE
// =======================================================
void _initAuth() {
  // Datasource
  serviceLocator.registerFactory<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(serviceLocator()), // supabase client
  );

  // Repository
  serviceLocator.registerFactory<AuthRepository>(
    () => AuthRepositoryImpl(
      serviceLocator(), // remote DS
      serviceLocator(), // connection checker
    ),
  );

  // Usecases
  serviceLocator.registerFactory(() => UserSignUp(serviceLocator()));
  serviceLocator.registerFactory(() => UserLogin(serviceLocator()));
  serviceLocator.registerFactory(() => CurrentUser(serviceLocator()));

  // Bloc
  serviceLocator.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      userSignUp: serviceLocator(),
      userLogin: serviceLocator(),
      currentUser: serviceLocator(),
      appUserCubit: serviceLocator(),
    ),
  );
}

// =======================================================
//                     BLOG MODULE
// =======================================================
void _initBlog() {
  // Datasource
  serviceLocator.registerFactory<BlogRemoteDataSource>(
    () => BlogRemoteDataSourceImpl(serviceLocator()), // supabase client
  );

  serviceLocator.registerFactory<BlogLocalDataSource>(
    () => BlogLocalDataSourceImpl(serviceLocator()), // hive box
  );

  // Repository
  serviceLocator.registerFactory<BlogRepository>(
    () => BlogRepositoryImpl(
      serviceLocator(), // Remote DS
      serviceLocator(), // Local DS
      serviceLocator(), // Connection checker
    ),
  );

  // Usecases
  serviceLocator.registerFactory(() => UploadBlog(serviceLocator()));
  serviceLocator.registerFactory(() => GetAllBlogs(serviceLocator()));

  // Bloc
  serviceLocator.registerLazySingleton<BlogBloc>(
    () => BlogBloc(uploadBlog: serviceLocator(), getAllBlogs: serviceLocator()),
  );
}
