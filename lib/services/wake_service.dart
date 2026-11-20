/// Wake word ("Hey Zoya") ka engine (Vosk) agle step me yahan judega.
/// Abhi sirf khali jagah hai, taaki baaki code na tute.
class WakeService {
  WakeService._();
  static final instance = WakeService._();

  Future<void> pause() async {}
  Future<void> resume() async {}
  Future<void> stop() async {}
}
