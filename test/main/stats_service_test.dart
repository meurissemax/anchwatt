import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('seeds the first-launch date once and keeps it across instances', () async {
    final StatsService service = StatsService();
    await service.init();

    final DateTime? first = service.firstLaunchDate;
    expect(first, isNotNull);

    final StatsService reopened = StatsService();
    await reopened.init();

    // The date is stored as a millisecond epoch, so compare at that granularity
    // (DateTime.now carries microseconds the persisted value intentionally drops).
    expect(
      reopened.firstLaunchDate?.millisecondsSinceEpoch,
      first?.millisecondsSinceEpoch,
    );
  });

  test('totalSystemEvents sums system events and excludes the pet', () async {
    final StatsService service = StatsService();
    await service.init();

    service.recordSystemEvent(AnchwattEventType.usbToggle);
    service.recordSystemEvent(AnchwattEventType.usbToggle);
    service.recordSystemEvent(AnchwattEventType.chargerToggle);
    service.recordSystemEvent(AnchwattEventType.pet);

    expect(service.eventCount(AnchwattEventType.usbToggle), 2);
    expect(service.eventCount(AnchwattEventType.chargerToggle), 1);
    expect(service.totalSystemEvents, 3);
  });

  test('recordSoundPlayed tracks the total and the per-mode split', () async {
    final StatsService service = StatsService();
    await service.init();

    service.recordSoundPlayed(SoundMode.corporate);
    service.recordSoundPlayed(SoundMode.corporate);
    service.recordSoundPlayed(SoundMode.friday);

    expect(service.soundsPlayed, 3);
    expect(service.soundsPlayedFor(SoundMode.corporate), 2);
    expect(service.soundsPlayedFor(SoundMode.friday), 1);
  });

  test('addLifetimeXp accumulates and ignores non-positive amounts', () async {
    final StatsService service = StatsService();
    await service.init();

    service.addLifetimeXp(10);
    service.addLifetimeXp(5);
    service.addLifetimeXp(0);
    service.addLifetimeXp(-3);

    expect(service.lifetimeXp, 15);
  });

  test('recordShinyEncounter increments the counter', () async {
    final StatsService service = StatsService();
    await service.init();

    service.recordShinyEncounter();
    service.recordShinyEncounter();

    expect(service.shinyEncounters, 2);
  });

  test('totalSoundDurationMs defaults to 0 on a fresh install', () async {
    final StatsService service = StatsService();
    await service.init();

    expect(service.totalSoundDurationMs, 0);
  });

  test('recordSoundDuration accumulates and ignores non-positive durations', () async {
    final StatsService service = StatsService();
    await service.init();

    service.recordSoundDuration(1500);
    service.recordSoundDuration(2500);
    service.recordSoundDuration(0);
    service.recordSoundDuration(-100);

    expect(service.totalSoundDurationMs, 4000);
  });

  test('persists counters across instances, keyed by enum name', () async {
    final StatsService service = StatsService();
    await service.init();

    service.recordSystemEvent(AnchwattEventType.headphonesToggle);
    service.recordPetInteraction();
    service.recordSoundPlayed(SoundMode.friday);
    service.addLifetimeXp(42);
    service.recordShinyEncounter();
    service.recordSoundDuration(1234);

    // Let the fire-and-forget writes settle before reopening.
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final StatsService reopened = StatsService();
    await reopened.init();

    expect(reopened.eventCount(AnchwattEventType.headphonesToggle), 1);
    expect(reopened.petInteractions, 1);
    expect(reopened.soundsPlayedFor(SoundMode.friday), 1);
    expect(reopened.lifetimeXp, 42);
    expect(reopened.shinyEncounters, 1);
    expect(reopened.totalSoundDurationMs, 1234);
  });

  test('reset zeroes every counter and reseeds the first-launch date', () async {
    final StatsService service = StatsService();
    await service.init();

    service.recordSystemEvent(AnchwattEventType.usbToggle);
    service.recordPetInteraction();
    service.recordSoundPlayed(SoundMode.corporate);
    service.addLifetimeXp(100);
    service.recordShinyEncounter();
    service.recordSoundDuration(1234);

    await service.reset();

    expect(service.totalSystemEvents, 0);
    expect(service.petInteractions, 0);
    expect(service.soundsPlayed, 0);
    expect(service.lifetimeXp, 0);
    expect(service.shinyEncounters, 0);
    expect(service.totalSoundDurationMs, 0);
    expect(service.firstLaunchDate, isNotNull);
  });
}
