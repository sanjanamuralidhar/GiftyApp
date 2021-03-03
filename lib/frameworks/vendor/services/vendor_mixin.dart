import '../../../services/service_config.dart';
import '../dokan.dart';
import '../wcfm.dart';
import 'dokan.dart';
import 'wcfm.dart';

mixin VendorMixin on ConfigMixin {
  configWCFM(appConfig) {
    WCFMApi().appConfig(appConfig);
    serviceApi = WCFMApi();
    widget = WCFMWidget();
  }

  configDokan(appConfig) {
    DokanApi().appConfig(appConfig);
    serviceApi = DokanApi();
    widget = DokanWidget();
  }
}
