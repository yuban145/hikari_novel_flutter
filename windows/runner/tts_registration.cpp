#include "tts_registration.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter_tts/flutter_tts_plugin.h>
#include <roapi.h>
#include <windows.media.speechsynthesis.h>
#include <wrl/client.h>
#include <wrl/wrappers/corewrappers.h>

#include <iostream>

namespace {
bool HasAccessibleVoice() {
  using namespace ABI::Windows::Media::SpeechSynthesis;
  using Microsoft::WRL::ComPtr;
  Microsoft::WRL::Wrappers::HStringReference class_name(
      RuntimeClass_Windows_Media_SpeechSynthesis_SpeechSynthesizer);
  ComPtr<IInstalledVoicesStatic> factory;
  if (FAILED(RoGetActivationFactory(class_name.Get(), IID_PPV_ARGS(&factory)))) {
    return false;
  }
  ComPtr<ABI::Windows::Foundation::Collections::IVectorView<VoiceInformation*>> voices;
  UINT32 count = 0;
  return SUCCEEDED(factory->get_AllVoices(&voices)) &&
      SUCCEEDED(voices->get_Size(&count)) && count > 0;
}
}  // namespace

void RegisterTtsSafely(FlutterDesktopPluginRegistrarRef registrar) {
  try {
    // Query through the HRESULT API before entering the third-party plugin.
    // Its WinRT constructor can terminate before an exception reaches us.
    if (HasAccessibleVoice()) {
      FlutterTtsPluginRegisterWithRegistrar(registrar);
      return;
    }
  } catch (...) {
    // Also handle other recoverable errors during optional registration.
  }
  // Keep other plugins and the reader usable, and report a Dart error.
  std::cerr << "Windows speech synthesis is unavailable." << std::endl;
  auto* windows_registrar = flutter::PluginRegistrarManager::GetInstance()
      ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar);
  flutter::MethodChannel<flutter::EncodableValue> channel(
      windows_registrar->messenger(), "flutter_tts",
      &flutter::StandardMethodCodec::GetInstance());
  channel.SetMethodCallHandler([](const auto&, auto result) {
    result->Error("tts_unavailable", "Windows speech synthesis is unavailable.");
  });
}
