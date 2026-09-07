import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart' as audio;
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';
import 'journal_content.dart';
import 'legal_text.dart';

String firebaseStorageMediaUrl(String fullPath) {
  final bucket = DefaultFirebaseOptions.currentPlatform.storageBucket;
  if (bucket == null || bucket.isEmpty || fullPath.isEmpty) return '';
  final encodedPath = Uri.encodeComponent(fullPath);
  return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedPath?alt=media';
}

Future<void> openExternalUrl(BuildContext context, String url) async {
  if (url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This Firebase file is not linked yet.')),
    );
    return;
  }

  final uri = Uri.parse(url);
  final opened = await launchUrl(
    uri,
    mode: LaunchMode.platformDefault,
    webOnlyWindowName: '_blank',
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open Firebase file: $url')),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const firebaseEnabled = bool.fromEnvironment('FIREBASE_ENABLED');
  const firebaseAuthEnabled = bool.fromEnvironment('FIREBASE_AUTH_ENABLED');
  String? authMessage;
  if (firebaseEnabled) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (firebaseAuthEnabled) {
      authMessage = await FirebaseAuthBootstrap.signInForStorageAccess();
    }
  }

  runApp(RedApp(firebaseEnabled: firebaseEnabled, authMessage: authMessage));
}

class RedApp extends StatelessWidget {
  const RedApp({
    required this.firebaseEnabled,
    required this.authMessage,
    super.key,
  });

  final bool firebaseEnabled;
  final String? authMessage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'red.',
      builder: (context, child) => PhonePreviewFrame(child: child),
      scrollBehavior: const RedScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: RedColors.background,
        textTheme: GoogleFonts.quicksandTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: RedColors.brand,
          brightness: Brightness.light,
        ),
      ),
      home: ContentBootstrap(
        firebaseEnabled: firebaseEnabled,
        authMessage: authMessage,
      ),
    );
  }
}

class ContentBootstrap extends StatelessWidget {
  const ContentBootstrap({
    required this.firebaseEnabled,
    required this.authMessage,
    super.key,
  });

  final bool firebaseEnabled;
  final String? authMessage;

  @override
  Widget build(BuildContext context) {
    if (!firebaseEnabled) {
      return LogoSplashScreen(content: AppContentData.local());
    }

    return FutureBuilder<AppContentData>(
      future: FirebaseContentService(authMessage: authMessage).load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingSplashScreen(
            message: 'Loading Firebase audio...',
          );
        }

        if (snapshot.hasError) {
          final error = snapshot.error?.toString();
          return LoadingSplashScreen(
            message: 'Firebase content could not load:\n$error',
          );
        }

        final content = snapshot.data ?? AppContentData.local();
        return LogoSplashScreen(
          content: content,
        );
      },
    );
  }
}

class FirebaseAuthBootstrap {
  static Future<String> signInForStorageAccess() async {
    try {
      final existingUser = FirebaseAuth.instance.currentUser;
      if (existingUser != null) {
        return 'Firebase Auth signed in: ${existingUser.isAnonymous ? "anonymous user" : existingUser.email ?? existingUser.uid}';
      }

      final credential = await FirebaseAuth.instance.signInAnonymously();
      return 'Firebase Auth signed in anonymously: ${credential.user?.uid ?? "unknown uid"}';
    } on FirebaseAuthException catch (error) {
      return 'Firebase Auth failed: ${error.code} - ${error.message ?? "No message"}';
    } catch (error) {
      return 'Firebase Auth failed: $error';
    }
  }
}

class RedScrollBehavior extends MaterialScrollBehavior {
  const RedScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class PhonePreviewFrame extends StatelessWidget {
  const PhonePreviewFrame({required this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF2F2F2),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: RedColors.background),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class RedColors {
  static const brand = Color(0xFFE21212);
  static const text = Color(0xFF111111);
  static const muted = Color(0xFF767676);
  static const background = Color(0xFFFAFAFA);
  static const card = Colors.white;
  static const line = Color(0xFFE9E9E9);
}

class AppContent {
  static const featured = [
    MeditationItem(
        'Radical Kindness',
        'Regenerative',
        '11 min',
        [
          Color(0xFFFFB4C2),
          Color(0xFFFFE3B5),
        ],
        imageAsset: 'assets/images/radical_kindness.png',
        coverShape: CoverShape.rectangle),
    MeditationItem(
        'This or Something Better',
        'Awakening',
        '11 min',
        [
          Color(0xFF926AE8),
          Color(0xFFFFB36D),
        ],
        imageAsset: 'assets/images/this_or_something_better.png',
        coverShape: CoverShape.rectangle),
    MeditationItem(
        'The Lucky Glow',
        'Angel Number 1010',
        '11 min',
        [
          Color(0xFFFFC36B),
          Color(0xFFFF8E7A),
        ],
        coverShape: CoverShape.rectangle),
  ];

  static const original14 = [
    MeditationItem(
        'Embrace Yourself',
        'Self-worth',
        '11 min',
        [
          Color(0xFFFF9AAE),
          Color(0xFF6E65DB),
        ],
        imageAsset: 'assets/images/embrace_yourself.png'),
    MeditationItem(
        'Inner Power',
        'Confidence',
        '11 min',
        [
          Color(0xFF5E5CE6),
          Color(0xFFFF8A3D),
        ],
        imageAsset: 'assets/images/inner_power.png'),
    MeditationItem('Rise and Shine', 'Morning ritual', '11 min', [
      Color(0xFFFFA76C),
      Color(0xFFFFE3A1),
    ]),
    MeditationItem(
        'Creation',
        'Universe Collection',
        '22 min',
        [
          Color(0xFF1E1D4A),
          Color(0xFFFF7A3D),
        ],
        imageAsset: 'assets/images/creation.png'),
    MeditationItem('Void', 'Universe Collection', '22 min', [
      Color(0xFF050512),
      Color(0xFF6C63FF),
    ]),
    MeditationItem('Time', 'Universe Collection', '22 min', [
      Color(0xFF352F44),
      Color(0xFFFFC857),
    ]),
  ];

  static const summerEscapes = [
    MeditationItem(
        'Yamas',
        'Summer Escapes',
        '11 min',
        [
          Color(0xFFFFB66E),
          Color(0xFF6BD2FF),
        ],
        imageAsset: 'assets/images/yamas.png'),
    MeditationItem(
        'Viva La Vida',
        'Summer Escapes',
        '11 min',
        [
          Color(0xFFE65A74),
          Color(0xFFFFD36E),
        ],
        imageAsset: 'assets/images/viva_la_vida.png'),
    MeditationItem(
      'Island of Infinite Opportunity',
      'Summer Escapes',
      '11 min',
      [Color(0xFF2DCCB3), Color(0xFF716CFF)],
    ),
  ];

  static const journeys = [
    JourneyItem('Creation', 'The Observer', '22 min'),
    JourneyItem('Void', 'The Quiet Space', '22 min'),
    JourneyItem('Time', 'The Soft Return', '22 min'),
  ];

  static const memberFavorites = [
    MeditationItem(
        'Radical Kindness',
        'Regenerative',
        '11 min',
        [
          Color(0xFFFFB4C2),
          Color(0xFFFFE3B5),
        ],
        imageAsset: 'assets/images/radical_kindness.png'),
    MeditationItem(
        'Inner Power',
        'Confidence',
        '11 min',
        [
          Color(0xFF5E5CE6),
          Color(0xFFFF8A3D),
        ],
        imageAsset: 'assets/images/inner_power.png'),
    MeditationItem('The Lucky Glow', 'Angel Number 1010', '11 min', [
      Color(0xFFFFC36B),
      Color(0xFFFF8E7A),
    ]),
  ];

  static const collectionDescription =
      'A seven-part guided journey for anyone standing at the edge of a new chapter. The Universe Collection helps you slow down, listen inward, and move through creation, emptiness, timing, wonder, patterns, expansion, and infinity with more clarity. Each meditation is paired with a journal so the insights do not disappear after the audio ends. Move through the series in order: listen first, then open the matching workbook to turn what surfaced into words, decisions, and direction.';
}

class AppContentData {
  const AppContentData({
    required this.featured,
    required this.original14,
    required this.summerEscapes,
    required this.memberFavorites,
    required this.journeys,
    required this.collectionDescription,
    required this.collectionDescriptionFromFirebase,
    required this.aboutRed,
    required this.privacyPolicy,
    required this.terms,
    this.debugMessages = const [],
  });

  final List<MeditationItem> featured;
  final List<MeditationItem> original14;
  final List<MeditationItem> summerEscapes;
  final List<MeditationItem> memberFavorites;
  final List<JourneyItem> journeys;
  final String collectionDescription;
  final bool collectionDescriptionFromFirebase;
  final String aboutRed;
  final String privacyPolicy;
  final String terms;
  final List<String> debugMessages;

  factory AppContentData.local() {
    return const AppContentData(
      featured: AppContent.featured,
      original14: AppContent.original14,
      summerEscapes: AppContent.summerEscapes,
      memberFavorites: AppContent.memberFavorites,
      journeys: AppContent.journeys,
      collectionDescription: AppContent.collectionDescription,
      collectionDescriptionFromFirebase: false,
      aboutRed: _aboutRed,
      privacyPolicy: LegalText.privacyPolicy,
      terms: LegalText.terms,
    );
  }
}

class FirebaseContentService {
  FirebaseContentService({
    this.authMessage,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final String? authMessage;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final List<String> _debugMessages = [];

  Future<AppContentData> load() async {
    final local = AppContentData.local();

    final meditations = await _safeLoad<List<MeditationItem>>(
      'meditations',
      _loadStorageMeditations,
      [],
    );
    final journeys = await _safeLoad<List<JourneyItem>>(
      'journeys',
      _loadStorageJourneys,
      [],
    );
    final text = await _safeLoad<Map<String, String>>(
      'app text',
      _loadText,
      {},
    );

    final firebaseCollectionDescription = text['collectionDescription']?.trim();

    return AppContentData(
      featured: _bySection(meditations, 'featured', const []),
      original14: _bySection(meditations, 'original14', const []),
      summerEscapes: _bySection(meditations, 'summerEscapes', const []),
      memberFavorites: _bySection(meditations, 'memberFavorites', const []),
      journeys: journeys,
      collectionDescription: firebaseCollectionDescription?.isNotEmpty == true
          ? firebaseCollectionDescription!
          : local.collectionDescription,
      collectionDescriptionFromFirebase:
          firebaseCollectionDescription?.isNotEmpty == true,
      aboutRed: _safeAboutText(text, local.aboutRed),
      privacyPolicy: _safePrivacyText(text, local.privacyPolicy),
      terms: _safeTermsText(text, local.terms),
      debugMessages: _presentationMessages(meditations.length, journeys.length),
    );
  }

  String _safeAboutText(Map<String, String> text, String fallback) {
    final value = _firstText(text, const ['aboutRed', 'about', 'about_red']);
    if (value == null) return fallback;
    final lower = value.toLowerCase();
    if (lower.contains('privacy policy') ||
        lower.contains('terms and conditions')) {
      _debugMessages.add(
          'About red. Firebase text looked like legal text; using local about text.');
      return fallback;
    }
    return value;
  }

  String _safePrivacyText(Map<String, String> text, String fallback) {
    final value =
        _firstText(text, const ['privacyPolicy', 'privacy', 'privacy_policy']);
    if (value == null) return fallback;
    final lower = value.toLowerCase();
    if (!lower.contains('privacy') && !lower.contains('personal data')) {
      _debugMessages.add(
          'Privacy Firebase text did not look like privacy content; using local privacy policy.');
      return fallback;
    }
    return value;
  }

  String _safeTermsText(Map<String, String> text, String fallback) {
    final value = _firstText(
      text,
      const ['terms', 'termsConditions', 'terms_and_conditions'],
    );
    if (value == null) return fallback;
    final lower = value.toLowerCase();
    if (!lower.contains('terms') && !lower.contains('eligibility')) {
      _debugMessages.add(
          'Terms Firebase text did not look like terms content; using local terms.');
      return fallback;
    }
    if (lower.contains('privacy policy') && !lower.contains('terms')) {
      _debugMessages.add(
          'Terms Firebase text looked like privacy content; using local terms.');
      return fallback;
    }
    return value;
  }

  String? _firstText(Map<String, String> text, List<String> keys) {
    for (final key in keys) {
      final value = text[key]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }

    final normalized = {
      for (final entry in text.entries)
        entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''):
            entry.value,
    };

    for (final key in keys) {
      final value = normalized[key.toLowerCase().replaceAll(
                RegExp(r'[^a-z0-9]'),
                '',
              )]
          ?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  List<String> _presentationMessages(int meditationCount, int journeyCount) {
    final protectedMediaFolders = _debugMessages.any(
      (message) =>
          message.startsWith('Could not read Storage file:') ||
          message.startsWith('Could not read known Storage path:'),
    );

    return [
      'Firebase Storage connected',
      'Meditations loaded from Firebase: $meditationCount',
      'Universe journeys loaded from Firebase: $journeyCount',
      if (protectedMediaFolders)
        'Some artwork/PDF folders are permission-protected; using prototype placeholders where needed.',
      if (authMessage != null &&
          !authMessage!.startsWith('Firebase Auth failed'))
        authMessage!,
    ];
  }

  Future<T> _safeLoad<T>(
    String label,
    Future<T> Function() loader,
    T fallback,
  ) async {
    try {
      return await loader();
    } catch (error) {
      _debugMessages.add('$label load failed: $error');
      return fallback;
    }
  }

  Future<List<MeditationItem>> _loadStorageMeditations() async {
    final audioFiles = <Reference>[];
    final restAudioPaths = await _restListStoragePaths('audio/');
    if (restAudioPaths.isNotEmpty) {
      audioFiles.addAll(restAudioPaths.map((path) => _storage.ref(path)));
      _debugMessages.add(
        'Firebase REST audio loaded: ${restAudioPaths.length} files from audio/.',
      );
    } else {
      audioFiles.addAll(await _recursiveFilesIn('audio'));
    }
    if (audioFiles.isEmpty) {
      audioFiles.addAll(_knownAudioRefs());
      _debugMessages
          .add('audio/ listing returned 0 files. Tried known audio paths.');
    }
    audioFiles.sort((a, b) => a.name.compareTo(b.name));
    final thumbnails = {
      ..._mediaUrlsForKnownPaths(_knownMeditationThumbnailPaths()),
      ...await _downloadUrlsByKey('meditation-thumbnails'),
    };

    final items = <MeditationItem>[];
    for (var index = 0; index < audioFiles.length; index++) {
      final audio = audioFiles[index];
      final title = _titleFromFile(audio.name);
      final key = _keyFromFile(audio.name);
      final section = _sectionForFile(audio.name, index);
      final duration = _durationFromFile(audio.name);
      final audioUrl = _firebaseMediaUrl(audio.fullPath);
      final thumbnailUrl = thumbnails[key] ?? '';
      debugPrint(
        'Firebase meditation mapped: $title | section=$section | file=${audio.fullPath} | thumbnail=${thumbnailUrl.isEmpty ? "pending" : thumbnailUrl}',
      );

      items.add(
        MeditationItem(
          title,
          'red. · Firebase Storage · $duration',
          duration,
          _paletteForIndex(index),
          imageAsset: thumbnailUrl.isEmpty ? null : thumbnailUrl,
          coverShape:
              section == 'featured' ? CoverShape.rectangle : CoverShape.square,
          section: section,
          description: 'Guided meditation from Firebase Storage.',
          audioUrl: audioUrl,
        ),
      );
    }
    return items;
  }

  Future<List<JourneyItem>> _loadStorageJourneys() async {
    final audioFiles = [
      ...await _recursiveFilesIn('audio'),
      ...await _recursiveFilesIn('Workshops_Courses'),
    ];
    final audioByKey = {
      for (final file in audioFiles) _keyFromFile(file.name): file
    };
    final detailImages = {
      ..._mediaUrlsForKnownPaths(_knownUniverseDetailImagePaths()),
      ...await _downloadUrlsByKey('collection-detail-thumbnails/universe'),
    };
    final pdfs = {
      ..._mediaUrlsForKnownPaths(_knownUniversePdfPaths()),
      ...await _downloadUrlsByKey('collection-pdfs/universe'),
    };
    var detailImageFiles =
        await _recursiveFilesIn('collection-detail-thumbnails/universe');
    if (detailImageFiles.isEmpty) {
      detailImageFiles = _knownUniverseDetailImagePaths()
          .map((path) => _storage.ref(path))
          .toList();
      _debugMessages.add(
        'collection-detail-thumbnails/universe listing returned 0 files. Tried known universe paths.',
      );
    }
    detailImageFiles.sort((a, b) => a.name.compareTo(b.name));

    final items = <JourneyItem>[];
    for (final image in detailImageFiles) {
      final key = _keyFromFile(image.name);
      final title = _universeTitleFromKey(key);
      final audio = audioByKey[key];
      final imagePath = _knownUniverseDetailImagePathForKey(key);
      final pdfPath = _knownUniversePdfPathForKey(key);
      final imageUrl = detailImages[key] ??
          (imagePath == null ? null : _firebaseMediaUrl(imagePath)) ??
          _localUniverseImageAssetForKey(key) ??
          '';
      final pdfUrl =
          pdfs[key] ?? (pdfPath == null ? '' : _firebaseMediaUrl(pdfPath));

      debugPrint(
        'Firebase journey mapped: $title | image=${imagePath ?? "missing"} | pdf=${pdfPath ?? "missing"} | audio=${audio?.fullPath ?? "pending"}',
      );

      items.add(
        JourneyItem(
          title,
          _universeSubtitle(title),
          '22 min',
          imageAsset: imageUrl.isEmpty ? null : imageUrl,
          description: _universeDescription(title),
          audioUrl: audio == null ? '' : await _safeDownloadUrl(audio),
          journalPdfUrl: pdfUrl,
        ),
      );
    }
    return items;
  }

  Future<Map<String, String>> _loadText() async {
    try {
      final snapshot = await _firestore.collection('app_text').doc('red').get();
      final data = snapshot.data();
      if (data == null) return {};
      return {
        for (final entry in data.entries)
          if (entry.value is String) entry.key: entry.value as String,
      };
    } catch (_) {
      _debugMessages.add('Firestore app_text/red could not load.');
      return {};
    }
  }

  List<MeditationItem> _bySection(
    List<MeditationItem> all,
    String section,
    List<MeditationItem> fallback,
  ) {
    final items = all.where((item) => item.section == section).toList();
    return items.isEmpty ? fallback : items;
  }

  Future<List<Reference>> _recursiveFilesIn(String folder) async {
    try {
      final root = _storage.ref(folder);
      return await _recursiveFilesFrom(root);
    } catch (_) {
      _debugMessages.add('Could not list Storage folder: $folder');
      return [];
    }
  }

  Future<List<Reference>> _recursiveFilesFrom(Reference ref) async {
    final result = await ref.listAll();
    final files = [...result.items];
    for (final prefix in result.prefixes) {
      files.addAll(await _recursiveFilesFrom(prefix));
    }
    return files;
  }

  Future<String> _safeDownloadUrl(Reference file) async {
    try {
      return await file.getDownloadURL();
    } catch (_) {
      _debugMessages.add('Could not read Storage file: ${file.fullPath}');
      return '';
    }
  }

  Future<List<String>> _restListStoragePaths(String prefix) async {
    final bucket = _storageBucketName;
    if (bucket.isEmpty) {
      _debugMessages
          .add('Firebase REST fallback skipped: missing bucket name.');
      return [];
    }

    final uri = Uri.https(
      'firebasestorage.googleapis.com',
      '/v0/b/$bucket/o',
      {'prefix': prefix},
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        _debugMessages.add(
          'Firebase REST list failed for $prefix: ${response.statusCode}.',
        );
        return [];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return [];
      final items = decoded['items'];
      if (items is! List) return [];

      return items
          .whereType<Map<String, dynamic>>()
          .map((item) => item['name'])
          .whereType<String>()
          .where((name) => name.isNotEmpty && !name.endsWith('/'))
          .toList();
    } catch (error) {
      _debugMessages.add('Firebase REST list failed for $prefix: $error');
      return [];
    }
  }

  String get _storageBucketName =>
      Firebase.app().options.storageBucket ??
      DefaultFirebaseOptions.currentPlatform.storageBucket ??
      '';

  String _firebaseMediaUrl(String fullPath) {
    return firebaseStorageMediaUrl(fullPath);
  }

  Future<Map<String, String>> _downloadUrlsByKey(String folder) async {
    final files = await _recursiveFilesIn(folder);
    final urls = <String, String>{};
    for (final file in files) {
      try {
        urls[_keyFromFile(file.name)] = await file.getDownloadURL();
      } catch (_) {
        _debugMessages.add('Could not read Storage file: ${file.fullPath}');
      }
    }
    return urls;
  }

  Map<String, String> _mediaUrlsForKnownPaths(List<String> paths) {
    return {
      for (final path in paths)
        _keyFromFile(_storage.ref(path).name): _firebaseMediaUrl(path),
    };
  }

  List<Reference> _knownAudioRefs() {
    return [
      'audio/A Letter from the Future [EN 10].mp3',
      'audio/A Letter from the Future [EN 20].mp3',
      'audio/Body Scan Energizer [EN 10].mp3',
      'audio/Body Scan Energizer [EN 20].mp3',
      'audio/La Dolce Vita [EN 10].mp3',
      'audio/La Dolce Vita [EN 20].mp3',
      'audio/Life is Beautiful [EN 10].mp3',
      'audio/Life is Beautiful [EN 20}.mp3',
      'Workshops_Courses/Your Best Life Sleep Meditation by Manifest with Neuroscience_app.mp3',
    ].map((path) => _storage.ref(path)).toList();
  }

  List<String> _knownMeditationThumbnailPaths() {
    return [
      'meditation-thumbnails/a-letter-from-the-future.png',
      'meditation-thumbnails/body-scan-energizer.png',
      'meditation-thumbnails/breath-of-serenity.png',
      'meditation-thumbnails/creative-awakening.png',
      'meditation-thumbnails/embrace-yourself.png',
      'meditation-thumbnails/floating-home.png',
      'meditation-thumbnails/inner-power.png',
      'meditation-thumbnails/island-of-infinite-opportunities.png',
      'meditation-thumbnails/la-dolce-vita.png',
      'meditation-thumbnails/letting-go.png',
      'meditation-thumbnails/life-is-beautiful.png',
      'meditation-thumbnails/new-joy-in-the-new-season.png',
      'meditation-thumbnails/nurturing-the-child-within.png',
      'meditation-thumbnails/peaceful-dusk.png',
      'meditation-thumbnails/radiant-vitality.png',
      'meditation-thumbnails/radical-kindness.png',
      'meditation-thumbnails/renewing-the-mind.png',
      'meditation-thumbnails/rise-and-shine.png',
      'meditation-thumbnails/roots-and-rhythms.png',
      'meditation-thumbnails/seeds-of-abundance.png',
      'meditation-thumbnails/the-art-of-detaching.png',
      'meditation-thumbnails/the-lucky-glow.png',
      'meditation-thumbnails/this-or-something-better.png',
      'meditation-thumbnails/viva-la-vida.png',
      'meditation-thumbnails/waves-of-renewal.png',
      'meditation-thumbnails/yamas.png',
    ];
  }

  List<String> _knownUniverseDetailImagePaths() {
    return [
      'collection-detail-thumbnails/universe/01-creation.png',
      'collection-detail-thumbnails/universe/02-void.png',
      'collection-detail-thumbnails/universe/03-time.png',
      'collection-detail-thumbnails/universe/04-stardust.png',
      'collection-detail-thumbnails/universe/05-orbit.png',
      'collection-detail-thumbnails/universe/06-expansion.png',
      'collection-detail-thumbnails/universe/07-infinity.png',
    ];
  }

  List<String> _knownUniversePdfPaths() {
    return [
      'collection-pdfs/universe/01-creation.pdf',
      'collection-pdfs/universe/02-void.pdf',
      'collection-pdfs/universe/03-time.pdf',
      'collection-pdfs/universe/04-stardust.pdf',
      'collection-pdfs/universe/05-orbit.pdf',
      'collection-pdfs/universe/06-expansion.pdf',
      'collection-pdfs/universe/07-infinity.pdf',
    ];
  }

  String? _knownUniverseDetailImagePathForKey(String key) {
    const paths = {
      'creation': 'collection-detail-thumbnails/universe/01-creation.png',
      'void': 'collection-detail-thumbnails/universe/02-void.png',
      'time': 'collection-detail-thumbnails/universe/03-time.png',
      'stardust': 'collection-detail-thumbnails/universe/04-stardust.png',
      'orbit': 'collection-detail-thumbnails/universe/05-orbit.png',
      'expansion': 'collection-detail-thumbnails/universe/06-expansion.png',
      'infinity': 'collection-detail-thumbnails/universe/07-infinity.png',
    };
    return paths[key];
  }

  String? _knownUniversePdfPathForKey(String key) {
    const paths = {
      'creation': 'collection-pdfs/universe/01-creation.pdf',
      'void': 'collection-pdfs/universe/02-void.pdf',
      'time': 'collection-pdfs/universe/03-time.pdf',
      'stardust': 'collection-pdfs/universe/04-stardust.pdf',
      'orbit': 'collection-pdfs/universe/05-orbit.pdf',
      'expansion': 'collection-pdfs/universe/06-expansion.pdf',
      'infinity': 'collection-pdfs/universe/07-infinity.pdf',
    };
    return paths[key];
  }

  String? _localUniverseImageAssetForKey(String key) {
    const assets = {
      'creation': 'assets/images/creation.png',
    };
    return assets[key];
  }

  String _keyFromFile(String name) {
    final raw = name
        .replaceAll(RegExp(r'\.[^.]+$'), '')
        .toLowerCase()
        .replaceAll(RegExp(r'\[[^\]]+\]'), '')
        .replaceAll(RegExp(r'^\d+[-_\s]*'), '')
        .replaceAll('_app', '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');

    const aliases = {
      'islandofinfiniteopportunities': 'islandofinfiniteopportunity',
      'islandofinfiniteopportunity': 'islandofinfiniteopportunity',
    };
    return aliases[raw] ?? raw;
  }

  String _titleFromFile(String name) {
    final noExtension = name.replaceAll(RegExp(r'\.[^.]+$'), '');
    final withoutLanguage =
        noExtension.replaceAll(RegExp(r'\[EN\s*\d+[\]\}]'), '');
    final withoutNumber =
        withoutLanguage.replaceAll(RegExp(r'^\d+[-_\s]*'), '');
    final spaced = withoutNumber
        .replaceAll('_app', '')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (spaced.isEmpty) return 'Untitled';
    return spaced
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _sectionForIndex(int index) {
    if (index < 3) return 'featured';
    if (index < 9) return 'original14';
    if (index < 12) return 'summerEscapes';
    return 'memberFavorites';
  }

  String _sectionForFile(String name, int index) {
    final key = _keyFromFile(name);
    const summer = {
      'yamas',
      'vivalavida',
      'ladolcevita',
      'islandofinfiniteopportunity',
    };
    if (summer.contains(key)) return 'summerEscapes';

    const originals = {
      'embraceyourself',
      'innerpower',
      'riseandshine',
      'creativeawakening',
      'breathofserenity',
      'floatinghome',
      'lettinggo',
      'newjoyinthenewseason',
      'nurturingthechildwithin',
      'peacefuldusk',
      'radiantvitality',
      'renewingthemind',
      'rootsandrhythms',
      'seedsofabundance',
      'theartofdetaching',
      'wavesofrenewal',
    };
    if (originals.contains(key)) return 'original14';

    const featured = {
      'radicalkindness',
      'thisorsomethingbetter',
      'theluckyglow',
      'aletterfromthefuture',
      'bodyscanenergizer',
      'lifeisbeautiful',
    };
    if (featured.contains(key)) return 'featured';

    return _sectionForIndex(index);
  }

  String _durationFromFile(String name) {
    final match =
        RegExp(r'\[EN\s*(\d+)[\]\}]', caseSensitive: false).firstMatch(name);
    if (match == null) return '11 min';
    return '${match.group(1)} min';
  }

  String _universeTitleFromKey(String key) {
    const titles = {
      'creation': 'Creation',
      'void': 'Void',
      'time': 'Time',
      'stardust': 'Stardust',
      'orbit': 'Orbit',
      'expansion': 'Expansion',
      'infinity': 'Infinity',
    };
    return titles[key] ?? _titleFromFile(key);
  }

  String _universeSubtitle(String title) {
    const subtitles = {
      'Creation': 'Begin at the source.',
      'Void': 'Enter the quiet field before form.',
      'Time': 'Soften your relationship with timing.',
      'Stardust': 'Remember the wonder you are made from.',
      'Orbit': 'Notice the patterns you keep circling.',
      'Expansion': 'Make room for the next version of you.',
      'Infinity': 'Stand at the edge of limitless possibility.',
    };
    return subtitles[title] ?? 'red.';
  }

  String _universeDescription(String title) {
    const descriptions = {
      'Creation':
          'This first journey invites you to reconnect with the power of attention: notice what your mind keeps proving, then choose what you want to create next.',
      'Void':
          'The beauty of stillness: make space for rest, silence, and the possibility that appears before the next chapter takes shape.',
      'Time':
          'A soft reset for urgency. Let timing become less of a pressure and more of a partner.',
      'Stardust':
          'A reminder that wonder is not outside you. Return to the quiet intelligence already moving through your body.',
      'Orbit':
          'Observe the loops, habits, and familiar patterns that pull you back. Choose the orbit that supports your becoming.',
      'Expansion':
          'Create inner room for more breath, more clarity, and more permission to grow beyond the old edge.',
      'Infinity':
          'A closing journey for openness, trust, and the possibility that your next chapter is wider than you imagined.',
    };
    return descriptions[title] ?? '';
  }

  List<Color> _paletteForIndex(int index) {
    const palettes = [
      [Color(0xFFFFB4C2), Color(0xFFFFE3B5)],
      [Color(0xFF926AE8), Color(0xFFFFB36D)],
      [Color(0xFFFFC36B), Color(0xFFFF8E7A)],
      [Color(0xFFFF9AAE), Color(0xFF6E65DB)],
      [Color(0xFF5E5CE6), Color(0xFFFF8A3D)],
      [Color(0xFFFFA76C), Color(0xFFFFE3A1)],
      [Color(0xFF1E1D4A), Color(0xFFFF7A3D)],
    ];
    return palettes[index % palettes.length];
  }
}

enum CoverShape { rectangle, square }

class MeditationItem {
  const MeditationItem(
    this.title,
    this.subtitle,
    this.duration,
    this.colors, {
    this.imageAsset,
    this.coverShape = CoverShape.square,
    this.section = 'featured',
    this.description = '',
    this.audioUrl = '',
  });
  final String title;
  final String subtitle;
  final String duration;
  final List<Color> colors;
  final String? imageAsset;
  final CoverShape coverShape;
  final String section;
  final String description;
  final String audioUrl;

  PlayerTrack toTrack() =>
      PlayerTrack(title, subtitle, duration, colors, imageAsset, audioUrl);
}

class JourneyItem {
  const JourneyItem(
    this.title,
    this.subtitle,
    this.duration, {
    this.imageAsset = 'assets/images/creation.png',
    this.description = '',
    this.audioUrl = '',
    this.journalPdfUrl = '',
  });
  final String title;
  final String subtitle;
  final String duration;
  final String? imageAsset;
  final String description;
  final String audioUrl;
  final String journalPdfUrl;

  PlayerTrack toTrack() => PlayerTrack(
        title,
        subtitle,
        duration,
        const [Color(0xFF1E1D4A), Color(0xFFFF7A3D)],
        imageAsset,
        audioUrl,
      );
}

class PlayerTrack {
  const PlayerTrack(
    this.title,
    this.subtitle,
    this.duration,
    this.colors,
    this.imageAsset,
    this.audioUrl,
  );
  final String title;
  final String subtitle;
  final String duration;
  final List<Color> colors;
  final String? imageAsset;
  final String audioUrl;
}

class LogoSplashScreen extends StatelessWidget {
  const LogoSplashScreen(
      {required this.content, this.bannerMessage, super.key});

  final AppContentData content;
  final String? bannerMessage;

  @override
  Widget build(BuildContext context) {
    return SplashFrame(
      bannerMessage: bannerMessage,
      child: const RedLogo(size: 42),
      onTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => IntroSplashScreen(content: content),
        ),
      ),
    );
  }
}

class LoadingSplashScreen extends StatelessWidget {
  const LoadingSplashScreen({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              const Center(child: RedLogo(size: 42)),
              const SizedBox(height: 22),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: RedColors.muted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class IntroSplashScreen extends StatelessWidget {
  const IntroSplashScreen({required this.content, super.key});

  final AppContentData content;

  @override
  Widget build(BuildContext context) {
    return SplashFrame(
      child: const Text(
        'red light therapy\nmeets mindfulness',
        textAlign: TextAlign.left,
        style: TextStyle(
          color: RedColors.text,
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () => Navigator.of(
        context,
      ).pushReplacement(
          MaterialPageRoute(builder: (_) => AppShell(content: content))),
    );
  }
}

class SplashFrame extends StatelessWidget {
  const SplashFrame({
    required this.child,
    required this.onTap,
    this.bannerMessage,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? bannerMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InkWell(
        onTap: onTap,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                Center(child: child),
                const Spacer(),
                const Text(
                  'Tap anywhere to continue',
                  style: TextStyle(color: RedColors.muted, fontSize: 12),
                ),
                if (bannerMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    bannerMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: RedColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({required this.content, super.key});

  final AppContentData content;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _isPlaying = false;
  bool _playerVisible = false;
  PlayerTrack? _currentTrack;
  late final audio.AudioPlayer _audioPlayer;
  late final ValueNotifier<PlayerTrack?> _trackNotifier;

  @override
  void initState() {
    super.initState();
    _audioPlayer = audio.AudioPlayer();
    _trackNotifier = ValueNotifier<PlayerTrack?>(null);
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing &&
            state.processingState != audio.ProcessingState.completed;
      });
    });
  }

  @override
  void dispose() {
    _trackNotifier.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(content: widget.content, onPlayMeditation: _startMeditation),
      CollectionsScreen(content: widget.content, onPlayJourney: _startJourney),
      MeditationScreen(
        content: widget.content,
        onPlayMeditation: _startMeditation,
      ),
      JournalScreen(content: widget.content, onPlayJourney: _startJourney),
      SettingsScreen(content: widget.content),
    ];

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(child: pages[_index]),
          if (_currentTrack != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 82,
              child: MiniPlayer(
                title: _currentTrack?.title ?? 'Creation',
                subtitle: _currentTrack?.subtitle ?? 'red.',
                imageAsset: _currentTrack?.imageAsset,
                isPlaying: _isPlaying,
                onToggle: _togglePlayback,
                onOpen: () {
                  if (_currentTrack != null) {
                    _openPlayer(_currentTrack!);
                  }
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color(0xFF9E9E9E),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 33,
        onTap: (value) {
          _selectTab(value);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CollectionsNavIcon(isSelected: false),
            activeIcon: CollectionsNavIcon(isSelected: true),
            label: 'Collections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_alt_outlined),
            activeIcon: Icon(Icons.psychology_alt_rounded),
            label: 'Meditations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book_rounded),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Future<void> _selectTab(int value) async {
    if (value == _index) return;

    await _audioPlayer.stop();
    if (!mounted) return;

    setState(() {
      _index = value;
      _isPlaying = false;
      _currentTrack = null;
      _trackNotifier.value = null;
    });
  }

  Future<void> _startMeditation(MeditationItem item) async {
    await _startTrack(item.toTrack());
  }

  Future<void> _startJourney(JourneyItem item) async {
    await _startTrack(item.toTrack());
  }

  Future<void> _startTrack(PlayerTrack track) async {
    if (track.audioUrl.isNotEmpty) {
      _showTrack(track);
      _openPlayer(track);
    }
    await _playTrack(track);
  }

  Future<bool> _playTrack(PlayerTrack track) async {
    _showTrack(track);

    if (track.audioUrl.isEmpty) {
      await _audioPlayer.stop();
      if (!mounted) return false;
      setState(() {
        _isPlaying = false;
        _currentTrack = null;
        _trackNotifier.value = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${track.title} does not have a Firebase audio file linked yet.',
          ),
        ),
      );
      return false;
    }

    try {
      debugPrint(
          'Trying Firebase audio URL for ${track.title}: ${track.audioUrl}');
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(track.audioUrl);
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _isPlaying = false;
        _currentTrack = null;
        _trackNotifier.value = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not play ${track.title}: $error'),
        ),
      );
      return false;
    }
  }

  void _showTrack(PlayerTrack track) {
    if (!mounted) return;
    setState(() {
      _isPlaying = true;
      _currentTrack = track;
      _trackNotifier.value = track;
    });
  }

  Future<void> _togglePlayback() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      if (_audioPlayer.processingState == audio.ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero);
      }
      await _audioPlayer.play();
    }
  }

  void _openPlayer(PlayerTrack track) {
    if (_playerVisible) return;
    _playerVisible = true;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AudioPlayerScreen(
              track: track,
              trackListenable: _trackNotifier,
              audioPlayer: _audioPlayer,
              isPlaying: _isPlaying,
              onToggle: _togglePlayback,
            ),
          ),
        )
        .whenComplete(() => _playerVisible = false);
  }
}

class CollectionsNavIcon extends StatelessWidget {
  const CollectionsNavIcon({required this.isSelected, super.key});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.black : const Color(0xFF9E9E9E);

    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 1,
            bottom: 0,
            child: Icon(Icons.nightlight_round, size: 31, color: color),
          ),
          Positioned(
            right: -2,
            top: -1,
            child: Icon(Icons.auto_awesome, size: 15, color: color),
          ),
        ],
      ),
    );
  }
}

class JournalScreen extends StatefulWidget {
  const JournalScreen({
    required this.content,
    required this.onPlayJourney,
    super.key,
  });

  final AppContentData content;
  final ValueChanged<JourneyItem> onPlayJourney;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  int _mode = 0;
  int _journeyIndex = 0;
  int _moodIndex = 0;
  bool _usedRedLight = true;
  bool _meditated = false;
  DateTime _visibleMonth = DateTime(2026, 7);
  DateTime _selectedDay = DateTime(2026, 7, 31);

  @override
  Widget build(BuildContext context) {
    final journeys = widget.content.journeys.isEmpty
        ? AppContent.journeys
        : widget.content.journeys;
    final selectedJourney =
        journeys[_journeyIndex.clamp(0, journeys.length - 1).toInt()];

    return AppScroll(
      children: [
        const Center(child: RedLogo(size: 34)),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'Glow Journal',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'A private ritual tracker for your red light and mindfulness practice. See what you meditated, how you felt, and what shifted after each session.',
          textAlign: TextAlign.center,
          style: TextStyle(color: RedColors.muted, height: 1.35, fontSize: 12),
        ),
        const SizedBox(height: 16),
        JournalModeSwitch(
          selectedIndex: _mode,
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 18),
        if (_mode == 0)
          _DailyGlowJournal(
            visibleMonth: _visibleMonth,
            selectedDay: _selectedDay,
            moodIndex: _moodIndex,
            usedRedLight: _usedRedLight,
            meditated: _meditated,
            onPreviousMonth: () => setState(
              () => _visibleMonth =
                  DateTime(_visibleMonth.year, _visibleMonth.month - 1),
            ),
            onNextMonth: () => setState(
              () => _visibleMonth =
                  DateTime(_visibleMonth.year, _visibleMonth.month + 1),
            ),
            onDaySelected: (day) => setState(() => _selectedDay = day),
            onMoodChanged: (value) => setState(() => _moodIndex = value),
            onRedLightChanged: (value) => setState(() => _usedRedLight = value),
            onMeditatedChanged: (value) => setState(() => _meditated = value),
          )
        else
          _UniverseJournal(
            journeys: journeys,
            selectedJourney: selectedJourney,
            selectedJourneyIndex: _journeyIndex,
            onJourneyChanged: (index) => setState(() => _journeyIndex = index),
            onPlayJourney: () => widget.onPlayJourney(selectedJourney),
            onOpenCollection: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CollectionDetailScreen(
                  content: widget.content,
                  onPlayJourney: widget.onPlayJourney,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class JournalModeSwitch extends StatelessWidget {
  const JournalModeSwitch({
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E6E3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _JournalModePill(
              label: 'Daily Glow',
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _JournalModePill(
              label: 'Universe Collection',
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalModePill extends StatelessWidget {
  const _JournalModePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: selected ? RedColors.text : RedColors.muted,
          ),
        ),
      ),
    );
  }
}

class _DailyGlowJournal extends StatelessWidget {
  const _DailyGlowJournal({
    required this.visibleMonth,
    required this.selectedDay,
    required this.moodIndex,
    required this.usedRedLight,
    required this.meditated,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDaySelected,
    required this.onMoodChanged,
    required this.onRedLightChanged,
    required this.onMeditatedChanged,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final int moodIndex;
  final bool usedRedLight;
  final bool meditated;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<int> onMoodChanged;
  final ValueChanged<bool> onRedLightChanged;
  final ValueChanged<bool> onMeditatedChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        JournalCalendarCard(
          visibleMonth: visibleMonth,
          selectedDay: selectedDay,
          onPreviousMonth: onPreviousMonth,
          onNextMonth: onNextMonth,
          onDaySelected: onDaySelected,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(radius: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fullDate(selectedDay),
                style: const TextStyle(
                  color: RedColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _JournalSwitchRow(
                label: 'I used my red light today',
                value: usedRedLight,
                onChanged: onRedLightChanged,
              ),
              _JournalSwitchRow(
                label: 'I meditated today',
                value: meditated,
                onChanged: onMeditatedChanged,
              ),
              const SizedBox(height: 16),
              const Text(
                'Mood after practice',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in [
                    'Calm',
                    'Clear',
                    'Soft',
                    'Energized',
                    'Heavy'
                  ].indexed)
                    ChoiceChip(
                      label: Text(entry.$2),
                      selected: moodIndex == entry.$1,
                      selectedColor: const Color(0xFFEAB8C4),
                      onSelected: (_) => onMoodChanged(entry.$1),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Journal note',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              TextField(
                minLines: 4,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Write what changed, softened, or became clear...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: RedColors.line),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _JournalButton(label: 'Save Glow Journal'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _RecentJournalNotes(),
      ],
    );
  }
}

class _UniverseJournal extends StatelessWidget {
  const _UniverseJournal({
    required this.journeys,
    required this.selectedJourney,
    required this.selectedJourneyIndex,
    required this.onJourneyChanged,
    required this.onPlayJourney,
    required this.onOpenCollection,
  });

  final List<JourneyItem> journeys;
  final JourneyItem selectedJourney;
  final int selectedJourneyIndex;
  final ValueChanged<int> onJourneyChanged;
  final VoidCallback onPlayJourney;
  final VoidCallback onOpenCollection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Universe Collection',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Answer the workbook prompts directly in your Glow Journal. Move through the journeys in order: listen first, then write what surfaced.',
          style: TextStyle(color: RedColors.muted, height: 1.38),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: journeys.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = selectedJourneyIndex == index;
              return ChoiceChip(
                label: Text(journeys[index].title),
                selected: selected,
                selectedColor: RedColors.brand,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : RedColors.text,
                  fontWeight: FontWeight.w800,
                ),
                onSelected: (_) => onJourneyChanged(index),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(radius: 22),
          child: Row(
            children: [
              ArtworkBox(
                title: selectedJourney.title,
                colors: const [Color(0xFF1E1D4A), Color(0xFFFF7A3D)],
                imageAsset: selectedJourney.imageAsset,
                width: 74,
                height: 74,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedJourney.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      selectedJourney.subtitle,
                      style: const TextStyle(color: RedColors.muted),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed:
                    selectedJourney.audioUrl.isEmpty ? null : onPlayJourney,
                icon: const Icon(Icons.play_arrow_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _UniversePromptCard(
          title: _promptTitleForJourney(selectedJourney.title),
          body: _promptBodyForJourney(selectedJourney.title),
        ),
        const _UniversePromptCard(
          title: 'What did this meditation make visible?',
          body:
              'Use this space for the exact thoughts, sensations, or decisions that appeared after listening.',
        ),
        TextField(
          minLines: 5,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: 'Write your ${selectedJourney.title} reflection...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: RedColors.line),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _JournalButton(label: 'Save Universe Reflection'),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onOpenCollection,
          icon: const Icon(Icons.auto_stories_rounded),
          label: const Text('Open Universe Collection'),
        ),
        const SizedBox(height: 18),
        const SectionTitle('Saved Creation reflections'),
        const SizedBox(height: 10),
        const _SavedReflectionCard(
          date: 'Sunday, Jul 5',
          body:
              'What is one belief about yourself or your life that you have been collecting evidence for?',
        ),
      ],
    );
  }
}

class JournalCalendarCard extends StatelessWidget {
  const JournalCalendarCard({
    required this.visibleMonth,
    required this.selectedDay,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDaySelected,
    super.key,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final daysInMonth =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;
    final cells = <DateTime?>[
      ...List<DateTime?>.filled(leadingEmpty, null),
      ...List.generate(
        daysInMonth,
        (index) => DateTime(visibleMonth.year, visibleMonth.month, index + 1),
      ),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 26),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  _monthTitle(visibleMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final day in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: RedColors.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            itemCount: cells.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              final day = cells[index];
              if (day == null) return const SizedBox.shrink();

              final selected = _sameDate(day, selectedDay);
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onDaySelected(day),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? RedColors.brand : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: RedColors.line),
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: selected ? Colors.white : RedColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CalendarLegendDot(color: RedColors.brand, label: 'Selected'),
              SizedBox(width: 14),
              _CalendarLegendDot(color: Color(0xFFEAB8C4), label: 'Red light'),
              SizedBox(width: 14),
              _CalendarLegendDot(color: Color(0xFF222222), label: 'Journal'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarLegendDot extends StatelessWidget {
  const _CalendarLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: RedColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _JournalSwitchRow extends StatelessWidget {
  const _JournalSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: value,
        activeThumbColor: RedColors.brand,
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        onChanged: onChanged,
      ),
    );
  }
}

class _UniversePromptCard extends StatelessWidget {
  const _UniversePromptCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: RedColors.muted, height: 1.38),
          ),
        ],
      ),
    );
  }
}

class _JournalButton extends StatelessWidget {
  const _JournalButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFB1072B),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saving will connect to Firebase journal entries.'),
            ),
          );
        },
        child: Text(label),
      ),
    );
  }
}

class _RecentJournalNotes extends StatelessWidget {
  const _RecentJournalNotes();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('Recent glow notes'),
        SizedBox(height: 10),
        _SavedReflectionCard(
          date: 'Tuesday, Jul 14',
          body: 'Clear · Red light · Meditated',
        ),
        _SavedReflectionCard(
          date: 'Thursday, Jul 9',
          body: 'Calm · Red light · Meditated',
        ),
      ],
    );
  }
}

class _SavedReflectionCard extends StatelessWidget {
  const _SavedReflectionCard({required this.date, required this.body});

  final String date;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(
            body,
            style: const TextStyle(color: RedColors.muted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

String _monthTitle(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _fullDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}

bool _sameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _promptTitleForJourney(String title) {
  if (title == 'Creation') {
    return 'What is one belief about yourself or your life that you have been collecting evidence for?';
  }
  return 'What is ${title.toLowerCase()} asking you to notice?';
}

String _promptBodyForJourney(String title) {
  if (title == 'Creation') {
    return 'Your brain loves being right. Open a form to a belief, a story, or expectation you have been proving. Is there a softer truth you can begin proving now?';
  }
  return 'Write what the meditation brought forward, then name one decision or direction you want to carry into the day.';
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.content,
    required this.onPlayMeditation,
    super.key,
  });

  final AppContentData content;
  final ValueChanged<MeditationItem> onPlayMeditation;

  @override
  Widget build(BuildContext context) {
    final playableItems = [
      ...content.featured,
      ...content.original14,
      ...content.summerEscapes,
      ...content.memberFavorites,
    ].where((item) => item.audioUrl.isNotEmpty).toList();
    final continuePlaying = playableItems.take(5).toList();
    final favorites = playableItems.skip(2).take(5).toList();

    return AppScroll(
      children: [
        const HomeHeroCard(),
        const SizedBox(height: 22),
        const SectionTitle('Continue Playing'),
        const SizedBox(height: 12),
        if (continuePlaying.isEmpty)
          const PendingContentCard(
            title: 'Continue Playing',
            body: 'Firebase audio is not available yet for this section.',
          )
        else
          HorizontalMeditationList(
            items: continuePlaying,
            onTap: onPlayMeditation,
          ),
        const SizedBox(height: 26),
        const SectionTitle('Favorites'),
        const SizedBox(height: 12),
        if (favorites.isEmpty)
          const PendingContentCard(
            title: 'Favorites',
            body:
                'Favorites will populate from Firebase once category metadata is available.',
          )
        else
          HorizontalMeditationList(
            items: favorites,
            onTap: onPlayMeditation,
          ),
      ],
    );
  }
}

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({
    required this.content,
    required this.onPlayJourney,
    super.key,
  });

  final AppContentData content;
  final ValueChanged<JourneyItem> onPlayJourney;

  @override
  Widget build(BuildContext context) {
    final mediaBlocked = content.debugMessages.any(
      (message) => message.contains('permission-protected'),
    );

    return AppScroll(
      children: [
        const PageTitle('Collections'),
        const SizedBox(height: 18),
        if (mediaBlocked) ...[
          const FirebaseMediaNotice(
            message:
                'Firebase Storage is connected, but collection thumbnails and PDFs are returning permission denied to the app.',
          ),
          const SizedBox(height: 18),
        ],
        CollectionListCard(
          description: content.collectionDescription,
          descriptionFromFirebase: content.collectionDescriptionFromFirebase,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CollectionDetailScreen(
                content: content,
                onPlayJourney: onPlayJourney,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        InfoCard(
          icon: Icons.auto_stories_rounded,
          title: 'Journal Guide',
          body:
              'The Creation journal PDF is included locally. Open the Universe Collection to preview prompts and reflection flow.',
          actionLabel: 'Ready',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const JournalGuideScreen())),
        ),
      ],
    );
  }
}

class CollectionDetailScreen extends StatelessWidget {
  const CollectionDetailScreen({
    required this.content,
    required this.onPlayJourney,
    super.key,
  });

  final AppContentData content;
  final ValueChanged<JourneyItem> onPlayJourney;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppScroll(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.chevron_left_rounded, size: 34),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const UniverseHero(),
          const SizedBox(height: 20),
          Text(
            content.collectionDescription,
            style: const TextStyle(
              color: RedColors.muted,
              height: 1.42,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          FirebaseSourceChip(
            fromFirebase: content.collectionDescriptionFromFirebase,
            firebaseLabel: 'Universe paragraph from Firebase',
            fallbackLabel:
                'Universe paragraph is local fallback; Firebase text was not readable',
          ),
          const SizedBox(height: 22),
          ...content.journeys.map(
            (journey) => JourneyTile(
              journey: journey,
              onPlay: () => onPlayJourney(journey),
            ),
          ),
          const SizedBox(height: 10),
          InfoCard(
            icon: Icons.picture_as_pdf_rounded,
            title: 'Journal Guide',
            body:
                'Universe Journal No. 1 - Creation is included locally for now. Open the preview to see the journal flow.',
            actionLabel: 'Open preview',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JournalGuideScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class JournalGuideScreen extends StatelessWidget {
  const JournalGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journal Guide')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
          children: [
            const UniverseHero(),
            const SizedBox(height: 20),
            const Text(
              JournalContent.creationEyebrow,
              style: TextStyle(
                color: RedColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              JournalContent.creationTitle,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              JournalContent.creationTheme,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: const Text(
                '"${JournalContent.creationQuote}"',
                style: TextStyle(
                  fontSize: 18,
                  height: 1.35,
                  fontFamily: 'Georgia',
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('How to Use This Journal'),
            const SizedBox(height: 10),
            ...JournalContent.howToUse.map((line) => BulletText(line)),
            const SizedBox(height: 22),
            const SectionTitle('Reflection Prompts'),
            const SizedBox(height: 10),
            ...JournalContent.prompts.indexed.map(
              (entry) => PromptCard(number: entry.$1 + 1, prompt: entry.$2),
            ),
            const SizedBox(height: 12),
            InfoCard(
              icon: Icons.folder_rounded,
              title: 'PDF asset',
              body: JournalContent.creationPdfAsset,
              actionLabel: 'Ready for PDF viewer later',
              onTap: () {},
            ),
            const SizedBox(height: 18),
            const Text(
              JournalContent.closing,
              style: TextStyle(color: RedColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class MeditationScreen extends StatelessWidget {
  const MeditationScreen({
    required this.content,
    required this.onPlayMeditation,
    super.key,
  });

  final AppContentData content;
  final ValueChanged<MeditationItem> onPlayMeditation;

  @override
  Widget build(BuildContext context) {
    final playableItems = [
      ...content.featured,
      ...content.original14,
      ...content.summerEscapes,
      ...content.memberFavorites,
    ].where((item) => item.audioUrl.isNotEmpty).toList();
    final mediaBlocked = content.debugMessages.any(
      (message) => message.contains('permission-protected'),
    );

    return AppScroll(
      children: [
        const Center(child: RedLogo(size: 34)),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'Mindfulness Menu',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 14),
        const SearchPill(hint: 'Search meditations'),
        const SizedBox(height: 22),
        if (mediaBlocked) ...[
          const FirebaseMediaNotice(
            message:
                'Firebase audio is readable, but meditation thumbnails are returning permission denied to the app.',
          ),
          const SizedBox(height: 22),
        ],
        const SectionTitle('Current Specials'),
        const SizedBox(height: 12),
        if (content.featured.isEmpty)
          const PendingContentCard(
            title: 'Current Specials',
            body: 'Waiting for Firebase content mapping for this category.',
          )
        else
          HorizontalMeditationList(
            items: content.featured,
            onTap: onPlayMeditation,
          ),
        const SizedBox(height: 26),
        const SectionTitle('The Summer Escapes'),
        const SizedBox(height: 12),
        if (content.summerEscapes.isEmpty)
          const PendingContentCard(
            title: 'The Summer Escapes',
            body:
                'Waiting for Firebase audio, artwork, and descriptions for this category.',
          )
        else
          HorizontalMeditationList(
            items: content.summerEscapes,
            onTap: onPlayMeditation,
          ),
        const SizedBox(height: 26),
        const SectionTitle('All Firebase Audio'),
        const SizedBox(height: 12),
        if (playableItems.isEmpty)
          const PendingContentCard(
            title: 'Firebase audio',
            body: 'No readable Firebase audio files are available to this app.',
          )
        else
          ...playableItems.map(
            (item) => MeditationRow(
              item: item,
              onTap: () => onPlayMeditation(item),
            ),
          ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.content, super.key});

  final AppContentData content;

  @override
  Widget build(BuildContext context) {
    return AppScroll(
      children: [
        const PageTitle('Settings'),
        const SizedBox(height: 16),
        ProfileHeader(
          onEdit: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
        ),
        const SizedBox(height: 18),
        const SectionLabel('Account Settings'),
        SettingsTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          onTap: () => _openText(
            context,
            'Change Password',
            'Password reset will connect to Firebase Authentication later.',
          ),
        ),
        SettingsTile(
          icon: Icons.credit_card_rounded,
          title: 'Manage Subscription',
          onTap: () => _openText(
            context,
            'Manage Subscription',
            'Subscription management will connect to Apple App Store / Google Play once payments are confirmed.',
          ),
        ),
        SettingsTile(
          icon: Icons.notifications_none_rounded,
          title: 'Push notifications',
          trailing: Switch(value: true, onChanged: (_) {}),
          onTap: () {},
        ),
        const SizedBox(height: 16),
        const SectionLabel('More'),
        SettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'About red.',
          onTap: () => _openText(context, 'About red.', content.aboutRed),
        ),
        SettingsTile(
          icon: Icons.shield_outlined,
          title: 'Privacy Policy',
          onTap: () =>
              _openText(context, 'Privacy Policy', content.privacyPolicy),
        ),
        SettingsTile(
          icon: Icons.description_outlined,
          title: 'Terms and conditions',
          onTap: () =>
              _openText(context, 'Terms and conditions', content.terms),
        ),
        SettingsTile(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Feedback',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const FeedbackScreen())),
        ),
        SettingsTile(
          icon: Icons.logout_rounded,
          title: 'Log Out',
          onTap: () => _openText(
            context,
            'Log Out',
            'Log out will be connected after Firebase Authentication is added.',
          ),
        ),
      ],
    );
  }

  void _openText(BuildContext context, String title, String body) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TextScreen(title: title, body: body),
      ),
    );
  }
}

class BulletText extends StatelessWidget {
  const BulletText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 6, color: RedColors.brand),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}

class FirebaseStatusCard extends StatelessWidget {
  const FirebaseStatusCard({required this.messages, super.key});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final hasLoadedContent =
        messages.any((message) => message.contains('loaded from Firebase:'));
    final preview = messages.take(5).join('\n');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasLoadedContent
            ? const Color(0xFFEFFFF5)
            : const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLoadedContent
              ? const Color(0xFFBFE8CB)
              : const Color(0xFFFFD88A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_done_rounded,
            color: hasLoadedContent
                ? const Color(0xFF248A4B)
                : const Color(0xFFB56A00),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              preview,
              style: TextStyle(
                color: hasLoadedContent
                    ? const Color(0xFF16552E)
                    : const Color(0xFF604000),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PromptCard extends StatelessWidget {
  const PromptCard({required this.number, required this.prompt, super.key});

  final int number;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: RedColors.brand,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              prompt,
              style: const TextStyle(height: 1.38, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

const _aboutRed = '''
Contact

Instagram: @better.at.red
Email: glow@betteratred.com
Website: betteratred.com

Red Labs GmbH
Talstrasse 1
8852 Altendorf, Switzerland

About red.

Our mission is simple: to help you become your best self — one breath, one light session, one insight at a time. When you show up to the world with clarity, calm, and confidence, you inspire others to do the same. And together, we create ripple effects of better decisions, healthier minds, and more connected lives.

red. is not a generic meditation library. It is a mindfulness app designed for red and near infrared light therapy rituals. The sessions are made for the moment when your device is on, your body is still, and you are ready to turn inward.

Red light therapy gives the body a clear ritual: pause, warm up, recover, soften. Meditation gives that ritual direction. Together, they create a practice that supports attention, regulation, and reflection.
''';

class AudioPlayerScreen extends StatelessWidget {
  const AudioPlayerScreen({
    required this.track,
    required this.trackListenable,
    required this.audioPlayer,
    required this.isPlaying,
    required this.onToggle,
    super.key,
  });

  final PlayerTrack track;
  final ValueListenable<PlayerTrack?> trackListenable;
  final audio.AudioPlayer audioPlayer;
  final bool isPlaying;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlayerTrack?>(
      valueListenable: trackListenable,
      builder: (context, currentTrack, _) {
        final visibleTrack = currentTrack ?? track;

        return Scaffold(
          appBar: AppBar(title: const Text('Now Playing')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
              child: Column(
                children: [
                  const Spacer(),
                  ArtworkBox(
                    title: visibleTrack.title,
                    colors: visibleTrack.colors,
                    imageAsset: visibleTrack.imageAsset,
                    width: double.infinity,
                    height: 280,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    visibleTrack.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    visibleTrack.subtitle,
                    style: const TextStyle(
                      color: RedColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  StreamBuilder<Duration>(
                    stream: audioPlayer.positionStream,
                    initialData: audioPlayer.position,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = audioPlayer.duration;
                      final totalMilliseconds =
                          duration?.inMilliseconds.toDouble() ?? 0;
                      final currentMilliseconds = totalMilliseconds <= 0
                          ? 0.0
                          : position.inMilliseconds
                              .toDouble()
                              .clamp(0.0, totalMilliseconds);

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 5,
                              activeTrackColor: RedColors.text,
                              inactiveTrackColor: RedColors.line,
                              thumbColor: RedColors.brand,
                              overlayColor:
                                  RedColors.brand.withValues(alpha: .12),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 18,
                              ),
                            ),
                            child: Slider(
                              min: 0,
                              max: totalMilliseconds <= 0
                                  ? 1
                                  : totalMilliseconds,
                              value: totalMilliseconds <= 0
                                  ? 0
                                  : currentMilliseconds,
                              onChanged: totalMilliseconds <= 0
                                  ? null
                                  : (value) {
                                      audioPlayer.seek(
                                        Duration(
                                          milliseconds: value.round(),
                                        ),
                                      );
                                    },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(
                                  color: RedColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                duration == null
                                    ? visibleTrack.duration
                                    : _formatDuration(duration),
                                style: const TextStyle(
                                  color: RedColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<audio.PlayerState>(
                    stream: audioPlayer.playerStateStream,
                    initialData: audioPlayer.playerState,
                    builder: (context, snapshot) {
                      final playing = snapshot.data?.playing ?? isPlaying;
                      final completed = snapshot.data?.processingState ==
                          audio.ProcessingState.completed;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filledTonal(
                            onPressed: () {
                              final target = audioPlayer.position -
                                  const Duration(seconds: 10);
                              audioPlayer.seek(
                                target.isNegative ? Duration.zero : target,
                              );
                            },
                            icon: const Icon(Icons.replay_10_rounded),
                          ),
                          const SizedBox(width: 22),
                          SizedBox(
                            width: 74,
                            height: 74,
                            child: IconButton.filled(
                              onPressed: onToggle,
                              iconSize: 42,
                              icon: Icon(
                                playing && !completed
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(width: 22),
                          IconButton.filledTonal(
                            onPressed: () {
                              final duration = audioPlayer.duration;
                              final target = audioPlayer.position +
                                  const Duration(seconds: 10);
                              audioPlayer.seek(
                                duration == null || target <= duration
                                    ? target
                                    : duration,
                              );
                            },
                            icon: const Icon(Icons.forward_10_rounded),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const JournalGuideScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.auto_stories_rounded),
                    label: const Text('Open Journal Guide'),
                  ),
                  if (visibleTrack.audioUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Audio loaded from Firebase Storage',
                      style: TextStyle(color: RedColors.muted, fontSize: 12),
                    ),
                  ],
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: AppScroll(
        children: [
          const Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: Color(0xFFE5E5E5),
              child: Text(
                'MR',
                style: TextStyle(
                  color: RedColors.muted,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionLabel('Personal Information'),
          const ProfileInfoTile(
            icon: Icons.person_outline_rounded,
            label: 'First Name',
            value: 'Mira',
          ),
          const ProfileInfoTile(
            icon: Icons.person_outline_rounded,
            label: 'Second Name',
            value: 'not set',
          ),
          const ProfileInfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: 'mira@example.com',
          ),
          const SizedBox(height: 18),
          const SectionLabel('Preferences & Additional Settings'),
          const ProfileInfoTile(
            icon: Icons.cake_outlined,
            label: 'Age',
            value: 'not set',
          ),
          const ProfileInfoTile(
            icon: Icons.wc_rounded,
            label: 'Gender',
            value: 'not set',
          ),
          const ProfileInfoTile(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: 'not set',
          ),
          const SizedBox(height: 18),
          InfoCard(
            icon: Icons.info_outline_rounded,
            title: 'Local profile preview',
            body:
                'These fields are placeholders until Firebase Authentication and user profiles are connected.',
            actionLabel: 'Ready for backend',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: AppScroll(
        children: [
          const Text(
            'Tell red. what could feel better.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const Text(
            'This is a local placeholder. Later, it can send feedback to email, Firestore, or a support tool.',
            style: TextStyle(color: RedColors.muted, height: 1.45),
          ),
          const SizedBox(height: 20),
          TextField(
            minLines: 6,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Write feedback...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: RedColors.line),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: () {}, child: const Text('Send Feedback')),
        ],
      ),
    );
  }
}

class TextScreen extends StatelessWidget {
  const TextScreen({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final sections = _parseLegalSections(body);
    final visibleSections = sections.isEmpty
        ? [
            LegalSection(
              title,
              body.trim().isEmpty
                  ? 'This content is not available from Firebase yet.'
                  : body.trim(),
            ),
          ]
        : sections;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: RedColors.background,
        surfaceTintColor: RedColors.background,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 34),
          itemCount: visibleSections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final section = visibleSections[index];
            final isFirst = index == 0;

            return Container(
              padding: EdgeInsets.all(isFirst ? 18 : 14),
              decoration: _cardDecoration(radius: isFirst ? 22 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    section.title,
                    style: TextStyle(
                      height: 1.3,
                      fontSize: isFirst ? 18 : 15,
                      color: RedColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (section.body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SelectableText(
                      section.body,
                      style: const TextStyle(
                        height: 1.48,
                        fontSize: 14,
                        color: RedColors.text,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class LegalSection {
  const LegalSection(this.title, this.body);

  final String title;
  final String body;
}

List<LegalSection> _parseLegalSections(String text) {
  final lines = text
      .split('\n')
      .map((line) => line.trimRight())
      .where((line) => line.trim().isNotEmpty)
      .toList();

  final sections = <LegalSection>[];
  final intro = <String>[];
  String? currentTitle;
  final currentBody = <String>[];
  final headingRegex = RegExp(r'^\d+\.\s+');

  void flushCurrent() {
    if (currentTitle != null) {
      sections.add(LegalSection(currentTitle!, currentBody.join('\n')));
      currentTitle = null;
      currentBody.clear();
    }
  }

  for (final line in lines) {
    if (headingRegex.hasMatch(line)) {
      if (currentTitle == null && intro.isNotEmpty) {
        sections.add(LegalSection(intro.first, intro.skip(1).join('\n')));
        intro.clear();
      }
      flushCurrent();
      currentTitle = line;
    } else if (currentTitle == null) {
      intro.add(line);
    } else {
      currentBody.add(line);
    }
  }

  if (intro.isNotEmpty) {
    sections.add(LegalSection(intro.first, intro.skip(1).join('\n')));
  }
  flushCurrent();
  return sections;
}

class AppScroll extends StatelessWidget {
  const AppScroll({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
      children: children,
    );
  }
}

class RedLogo extends StatelessWidget {
  const RedLogo({this.size = 32, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      'red.',
      style: GoogleFonts.abrilFatface(
        color: RedColors.brand,
        fontSize: size,
        height: 1,
      ),
    );
  }
}

class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 560,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFBF4),
            Color(0xFFFFF2DF),
            Color(0xFFEECF9C),
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: -40,
            top: 58,
            child: Icon(
              Icons.local_florist_outlined,
              size: 170,
              color: Colors.white.withValues(alpha: .45),
            ),
          ),
          Positioned(
            right: -80,
            bottom: -34,
            child: Container(
              width: 330,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: .24),
              ),
            ),
          ),
          const Positioned(
            top: 34,
            left: 0,
            right: 0,
            child: Center(child: RedLogo(size: 40)),
          ),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HELLO YOU',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: Color(0xFF5E5246),
                    fontSize: 28,
                    letterSpacing: 4.2,
                    height: 1.35,
                  ),
                ),
                Text(
                  'BEAUTIFUL SOUL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: Color(0xFF5E5246),
                    fontSize: 28,
                    letterSpacing: 4.2,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 18),
                SizedBox(
                  width: 170,
                  child: Divider(color: Color(0xFFB9AA98), thickness: .8),
                ),
                SizedBox(height: 18),
                Text(
                  'Take a breath, choose one\nsmall practice and let the\nday meet you more softly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7C7168),
                    fontSize: 15,
                    height: 1.75,
                    letterSpacing: 3.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
    );
  }
}

class SearchPill extends StatelessWidget {
  const SearchPill({required this.hint, super.key});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: RedColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: RedColors.muted, size: 18),
          const SizedBox(width: 8),
          Text(
            hint,
            style: const TextStyle(color: RedColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class PendingContentCard extends StatelessWidget {
  const PendingContentCard({
    required this.title,
    required this.body,
    super.key,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RedColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_queue_rounded, color: RedColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: RedColors.muted,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: RedColors.muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class FirebaseMediaNotice extends StatelessWidget {
  const FirebaseMediaNotice({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7B762)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, color: Color(0xFF8A5A10)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7A4A08),
                height: 1.35,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HorizontalMeditationList extends StatefulWidget {
  const HorizontalMeditationList({
    required this.items,
    required this.onTap,
    super.key,
  });

  final List<MeditationItem> items;
  final ValueChanged<MeditationItem> onTap;

  @override
  State<HorizontalMeditationList> createState() =>
      _HorizontalMeditationListState();
}

class _HorizontalMeditationListState extends State<HorizontalMeditationList> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 238,
          child: Scrollbar(
            controller: _controller,
            thumbVisibility: true,
            radius: const Radius.circular(99),
            thickness: 3,
            child: ListView.separated(
              controller: _controller,
              padding: const EdgeInsets.only(bottom: 10, right: 18),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) => MeditationCover(
                item: widget.items[index],
                onTap: () => widget.onTap(widget.items[index]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Drag sideways to explore',
          style: TextStyle(color: RedColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class MeditationCover extends StatelessWidget {
  const MeditationCover({required this.item, required this.onTap, super.key});

  final MeditationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coverHeight = item.coverShape == CoverShape.rectangle ? 88.0 : 126.0;
    final hasAudio = item.audioUrl.isNotEmpty;

    return SizedBox(
      width: 144,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArtworkBox(
              title: item.title,
              colors: item.colors,
              imageAsset: item.imageAsset,
              width: double.infinity,
              height: coverHeight,
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: RedColors.muted,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              hasAudio ? item.duration : 'Audio mapping pending',
              style: const TextStyle(fontSize: 12, color: RedColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class ArtworkBox extends StatelessWidget {
  const ArtworkBox({
    required this.title,
    required this.colors,
    this.imageAsset,
    this.width,
    this.height = 96,
    super.key,
  });

  final String title;
  final List<Color> colors;
  final String? imageAsset;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: _image(),
    );
  }

  Widget _image() {
    final source = imageAsset;
    if (source == null || source.isEmpty) return _fallbackText();

    if (source.startsWith('http')) {
      return Image.network(
        source,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, error, ___) {
          debugPrint('Image failed to load: $source | $error');
          return _fallbackText();
        },
      );
    }

    return Image.asset(
      source,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallbackText(),
    );
  }

  Widget _fallbackText() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.05,
          fontWeight: FontWeight.w900,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

class LargeNowPlayingCard extends StatelessWidget {
  const LargeNowPlayingCard({required this.onPlay, super.key});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const ArtworkBox(
            title: 'Creation',
            colors: [Color(0xFF1E1D4A), Color(0xFFFF7A3D)],
            imageAsset: 'assets/images/creation.png',
            width: 58,
            height: 58,
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Creation', style: TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  'red.',
                  style: TextStyle(color: RedColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }
}

class HomeCollectionCard extends StatelessWidget {
  const HomeCollectionCard({
    required this.description,
    required this.onOpen,
    super.key,
  });

  final String description;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(radius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const UniverseHero(),
            const SizedBox(height: 14),
            const Text(
              'Universe Collection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: RedColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class CollectionListCard extends StatelessWidget {
  const CollectionListCard({
    required this.description,
    required this.descriptionFromFirebase,
    required this.onTap,
    super.key,
  });

  final String description;
  final bool descriptionFromFirebase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(radius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const UniverseHero(),
            const SizedBox(height: 14),
            const Text(
              'Universe Collection',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(color: RedColors.muted, height: 1.42),
            ),
            const SizedBox(height: 10),
            FirebaseSourceChip(
              fromFirebase: descriptionFromFirebase,
              firebaseLabel: 'Text from Firebase',
              fallbackLabel: 'Text fallback',
            ),
            const SizedBox(height: 10),
            const Text(
              'Open collection',
              style: TextStyle(
                color: RedColors.brand,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FirebaseSourceChip extends StatelessWidget {
  const FirebaseSourceChip({
    required this.fromFirebase,
    required this.firebaseLabel,
    required this.fallbackLabel,
    super.key,
  });

  final bool fromFirebase;
  final String firebaseLabel;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fromFirebase ? const Color(0xFFEAF7EF) : const Color(0xFFFFF4E4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              fromFirebase ? const Color(0xFF6BB986) : const Color(0xFFE3B268),
        ),
      ),
      child: Text(
        fromFirebase ? firebaseLabel : fallbackLabel,
        style: TextStyle(
          color:
              fromFirebase ? const Color(0xFF2D7A46) : const Color(0xFF8A5A10),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class UniverseHero extends StatelessWidget {
  const UniverseHero({super.key});

  @override
  Widget build(BuildContext context) {
    final coverUrl = firebaseStorageMediaUrl(
        'collection-thumbnails/universe-collection-cover.png');

    return Container(
      height: 154,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: coverUrl.isEmpty
          ? const UniverseHeroLocalCover()
          : Image.network(
              coverUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              errorBuilder: (_, error, ___) {
                debugPrint('Universe cover failed to load: $coverUrl | $error');
                return const UniverseHeroLocalCover();
              },
            ),
    );
  }
}

class UniverseHeroLocalCover extends StatelessWidget {
  const UniverseHeroLocalCover({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.translate(
          offset: const Offset(0, -28),
          child: Image.asset(
            'assets/images/universe_collection.png',
            width: double.infinity,
            height: 206,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, __, ___) => const UniverseHeroFallback(),
          ),
        ),
      ],
    );
  }
}

class UniverseHeroFallback extends StatelessWidget {
  const UniverseHeroFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF070719), Color(0xFF283C88), Color(0xFFFF6B33)],
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        'UNIVERSE\nCOLLECTION',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 25,
          letterSpacing: 3,
          height: 1.2,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class JourneyTile extends StatelessWidget {
  const JourneyTile({required this.journey, required this.onPlay, super.key});

  final JourneyItem journey;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final hasAudio = journey.audioUrl.isNotEmpty;
    final hasPdf = journey.journalPdfUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArtworkBox(
            title: journey.title,
            colors: const [Color(0xFF1E1D4A), Color(0xFFFF7A3D)],
            imageAsset: journey.imageAsset,
            width: 98,
            height: 98,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  journey.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  journey.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RedColors.muted,
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (journey.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    journey.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RedColors.muted,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  hasAudio ? journey.duration : 'Audio mapping pending',
                  style: const TextStyle(color: RedColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: hasAudio ? 'Play audio' : 'Audio mapping pending',
                onPressed: hasAudio ? onPlay : null,
                icon: Icon(
                  hasAudio
                      ? Icons.play_arrow_rounded
                      : Icons.cloud_queue_rounded,
                  size: 32,
                ),
              ),
              IconButton(
                tooltip: hasPdf ? 'Open journal PDF' : 'PDF mapping pending',
                onPressed: hasPdf
                    ? () => openExternalUrl(context, journey.journalPdfUrl)
                    : null,
                icon: Icon(
                  hasPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.article_outlined,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MeditationRow extends StatelessWidget {
  const MeditationRow({required this.item, required this.onTap, super.key});

  final MeditationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAudio = item.audioUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          ArtworkBox(
            title: item.title,
            colors: item.colors,
            imageAsset: item.imageAsset,
            width: 62,
            height: 62,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  hasAudio ? item.subtitle : '${item.subtitle} - audio pending',
                  style: const TextStyle(color: RedColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: hasAudio ? onTap : null,
            icon: Icon(
              hasAudio
                  ? Icons.play_circle_fill_rounded
                  : Icons.cloud_queue_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    required this.title,
    required this.subtitle,
    this.imageAsset,
    required this.isPlaying,
    required this.onToggle,
    required this.onOpen,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? imageAsset;
  final bool isPlaying;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: _cardDecoration(radius: 18).copyWith(
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            ArtworkBox(
              title: 'red.',
              colors: const [Color(0xFF161640), Color(0xFFFF7042)],
              imageAsset: imageAsset,
              width: 44,
              height: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: RedColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onToggle,
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.onEdit, super.key});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFE5E5E5),
            child: Text(
              'MR',
              style: TextStyle(
                color: RedColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mira', style: TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  'mira@example.com',
                  style: TextStyle(color: RedColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text('Edit Profile')),
        ],
      ),
    );
  }
}

class ProfileInfoTile extends StatelessWidget {
  const ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _cardDecoration(radius: 16),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon),
          title:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(value),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _cardDecoration(radius: 16),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: RedColors.brand),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      color: RedColors.muted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    actionLabel,
                    style: const TextStyle(
                      color: RedColors.brand,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({double radius = 20}) {
  return BoxDecoration(
    color: RedColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: RedColors.line),
  );
}
