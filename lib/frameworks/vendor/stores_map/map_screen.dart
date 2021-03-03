import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../generated/l10n.dart';
import '../../../models/vendor/store_model.dart';
import '../../../widgets/common/skeleton.dart';
import 'map_screen_model.dart';
import 'store_banner.dart';
import 'widgets/map_address_search_widget.dart';

/// Map Screen
class MapScreen extends StatefulWidget {
  MapScreen();

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  _onMapCreated(GoogleMapController controller, MapModel mapModel) async {
    mapModel.mapController = controller;
    //changeMapMode();
  }

  _moveToStore(Store store, MapModel mapModel) {
    mapModel.mapController.animateCamera(
      CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(store.lat, store.long), zoom: 11.0)),
    );
  }

  _buildCarousel(double width, List<Store> stores, MapModel mapModel) {
    if (stores.isEmpty) {
      return Container();
    }
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        width: width,
        height: width * 0.5,
        padding: const EdgeInsets.only(bottom: 20, top: 10),
        child: Swiper(
          key: const Key("vendors"),
          loop: false,
          viewportFraction: 0.6,
          scale: 0.8,
          itemBuilder: (context, index) {
            final store = stores[index];
            if (store == null || store.lat == null || store.long == null) {
              return const SizedBox();
            }
            return StoreBanner(
              store: stores[index],
              width: width,
              moveToStore: () => _moveToStore(store, mapModel),
            );
          },
          itemCount: stores.length,
          onIndexChanged: (index) {
            if (kVendorConfig['ShowAllVendorMarkers'] == null &&
                !kVendorConfig['ShowAllVendorMarkers']) {
              mapModel.markers.clear();
              mapModel.markers.add(Marker(
                  markerId: MarkerId('${stores[index].id}'),
                  infoWindow:
                      InfoWindow(title: stores[index].name, onTap: () {}),
                  position: LatLng(stores[index].lat, stores[index].long)));
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  _buildEmptyCarousel(width) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        width: width,
        height: width * 0.5,
        padding: const EdgeInsets.only(bottom: 20, top: 10),
        child: Swiper(
          key: const Key("empty"),
          loop: false,
          viewportFraction: 0.6,
          scale: 0.8,
          itemBuilder: (context, index) {
            return Skeleton(
              width: width * 0.2,
              height: width * 0.5,
            );
          },
          itemCount: 5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ModalRoute<dynamic> parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;
    return LayoutBuilder(builder: (context, constraints) {
      var width = constraints.maxWidth;
      return Scaffold(
        resizeToAvoidBottomPadding: false,
        body: ChangeNotifierProvider<MapModel>(
          create: (context) => MapModel(),
          child: Consumer<MapModel>(
            builder: (context, mapModel, _) {
              switch (mapModel.viewState) {
                case ViewState.Loaded:
                  return Stack(
                    children: <Widget>[
                      Container(
                        width: width,
                        height: MediaQuery.of(context).size.height,
                        child: GoogleMap(
                          zoomControlsEnabled: false,
                          mapType: MapType.normal,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              mapModel.userLocation.latitude,
                              mapModel.userLocation.longitude,
                            ),
                            zoom: 11.0,
                          ),
                          onMapCreated: (controller) =>
                              _onMapCreated(controller, mapModel),
                          markers: mapModel.markers,
                        ),
                      ),
                      if (mapModel.listStore.isNotEmpty)
                        _buildCarousel(
                          constraints.maxWidth,
                          mapModel.listStore,
                          mapModel,
                        ),
                      SafeArea(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 10),
                            if (canPop)
                              InkWell(
                                onTap: Navigator.of(context).pop,
                                child: const Icon(
                                  Icons.close,
                                  size: 28,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 15.0),
                                    height: 35.0,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: MapAddressSearchWidget(
                                            controller:
                                                mapModel.addressController,
                                            focusNode:
                                                mapModel.addressFocusNode,
                                            onChangedCallBack:
                                                mapModel.getAutocompletePlaces,
                                            onSubmittedCallBack:
                                                mapModel.getLocationFromPlace,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        InkWell(
                                            onTap: () => mapModel
                                                .getLocationFromPlace(0),
                                            child: Text(S
                                                .of(context)
                                                .ok
                                                .toUpperCase())),
                                        const SizedBox(width: 20),
                                      ],
                                    ),
                                  ),
                                  if (mapModel.autocompletePlaces.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(
                                          top: 5.0, left: 20, right: 70.0),
                                      padding: const EdgeInsets.all(
                                        10.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: List.generate(
                                            mapModel.autocompletePlaces.length,
                                            (index) => InkWell(
                                                  onTap: () => mapModel
                                                      .getLocationFromPlace(
                                                          index),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons
                                                          .location_on_rounded),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          mapModel
                                                              .autocompletePlaces[
                                                                  index]
                                                              .description,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                case ViewState.Loading:
                  return Stack(
                    children: <Widget>[
                      Container(
                        width: width,
                        height: MediaQuery.of(context).size.height,
                        child: GoogleMap(
                          mapType: MapType.normal,
                          zoomControlsEnabled: false,
                          initialCameraPosition: CameraPosition(
                              target: LatLng(
                                mapModel.userLocation == null
                                    ? 0.0
                                    : mapModel.userLocation.latitude,
                                mapModel.userLocation == null
                                    ? 0.0
                                    : mapModel.userLocation.longitude,
                              ),
                              zoom: 11.0),
                          onMapCreated: (controller) =>
                              _onMapCreated(controller, mapModel),
                        ),
                      ),
                      _buildEmptyCarousel(width),
                      SafeArea(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 10),
                            if (canPop)
                              InkWell(
                                onTap: Navigator.of(context).pop,
                                child: const Icon(
                                  Icons.close,
                                  size: 28,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 15.0),
                                    height: 35.0,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: MapAddressSearchWidget(
                                            controller:
                                                mapModel.addressController,
                                            focusNode:
                                                mapModel.addressFocusNode,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(S.of(context).ok.toUpperCase()),
                                        const SizedBox(width: 20),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                default:
                  return Container(
                    width: width,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.grey,
                  );
              }
            },
          ),
        ),
      );
    });
  }
}
