import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:giftty/Cart.dart';
import 'package:giftty/ProductList.dart';
import 'package:giftty/Rating_Review.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

import 'Favorite.dart';
import 'Helper/AppBtn.dart';
import 'Helper/Color.dart';
import 'Helper/Constant.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'Home.dart';
import 'Login.dart';
import 'Model/Section_Model.dart';
import 'Model/User.dart';
import 'Product_Preview.dart';
import 'bloc/bloc.dart';

class ProductDetail extends StatefulWidget {
  final Product model;

  final Function updateHome;
  final Function updateParent;
  final int secPos, index;
  final bool list;

  const ProductDetail(
      {Key key,
      this.model,
      this.updateParent,
      this.updateHome,
      this.secPos,
      this.index,
      this.list})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => StateItem();
}

List<String> sliderList = [];
List<User> reviewList = [];
int offset = 0;
int total = 0;

class StateItem extends State<ProductDetail> with TickerProviderStateMixin {
  int _curSlider = 0;
  final _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  List<int> _selectedIndex = [];
  ChoiceChip choiceChip, tagChip;
  int _oldSelVarient = 0;
  bool _isProgress = false, _isLoading = true;

  Animation buttonSqueezeanimation;
  AnimationController buttonController;
  bool _isNetworkAvail = true;

  int notificationoffset = 0;
  ScrollController notificationcontroller;
  bool notificationisloadmore = true,
      notificationisgettingdata = false,
      notificationisnodata = false;
  List<Product> productList = [];

  var isDarkTheme;
  ShortDynamicLink shortenedLink;
  String shareLink;
  ProductDetailBloc productDetailBloc;
  FavBloc sampleBloc;

  @override
  void initState() {
    super.initState();
    sampleBloc = BlocProvider.of<FavBloc>(context);
    productDetailBloc = BlocProvider.of<ProductDetailBloc>(context);
    productDetailBloc.add(ParameterProductDetailEvent(
      categoryId: widget.model.categoryId,
      limit: perPage.toString(),
      id:notificationoffset.toString(),
      offset: widget.model.id,
      isSimilar: "1",
    ));

    print('${widget.model.categoryId},${perPage.toString()},${notificationoffset.toString()},${widget.model.id}');

    sliderList.clear();
    sliderList.add(widget.model.image);
    if (widget.model.videType != null &&
        widget.model.video != null &&
        widget.model.video.isNotEmpty &&
        widget.model.video != "") sliderList.add(widget.model.image);
    sliderList.addAll(widget.model.otherImage);

    for (int i = 0; i < widget.model.prVarientList.length; i++) {
      for (int j = 0; j < widget.model.prVarientList[i].images.length; j++) {
        sliderList.add(widget.model.prVarientList[i].images[j]);
      }
    }

    getShare();

    _oldSelVarient = widget.model.selVarient;

    reviewList.clear();
    offset = 0;
    total = 0;
    getReview();
    notificationoffset = 0;
    // getProduct();

    notificationcontroller = ScrollController(keepScrollOffset: true);
    notificationcontroller.addListener(_transactionscrollListener);

    buttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = new Tween(
      begin: deviceWidth * 0.7,
      end: 50.0,
    ).animate(new CurvedAnimation(
      parent: buttonController,
      curve: new Interval(
        0.0,
        0.150,
      ),
    ));
  }

  _transactionscrollListener() {
    if (notificationcontroller.offset >=
            notificationcontroller.position.maxScrollExtent &&
        !notificationcontroller.position.outOfRange) {
      if (mounted)
        setState(() {
          getProduct();
        });
    }
  }

  @override
  void dispose() {
    buttonController.dispose();
    notificationcontroller.dispose();
    super.dispose();
  }

  Future<void> createDynamicLink() async {
    // ignore: unused_local_variable
    var documentDirectory;

    if (Platform.isIOS)
      documentDirectory = (await getApplicationDocumentsDirectory()).path;
    else
      documentDirectory = (await getExternalStorageDirectory()).path;

    var request = await HttpClient().getUrl(Uri.parse(widget.model.image));
    var response = await request.close();
    Uint8List bytes = await consolidateHttpClientResponseBytes(response);
    await Share.file(
      widget.model.name,
      '${widget.model.name}.jpg',
      bytes,
      'image/jpg',
      text:
          "${widget.model.name}\n${shortenedLink.shortUrl.toString()}\n$shareLink",
    );
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController.forward();
    } on TickerCanceled {}
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();

              Future.delayed(Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => super.widget));
                } else {
                  await buttonController.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    return Scaffold(
      key: _scaffoldKey,
      body: _isNetworkAvail
          // ? BlocListener<ProductDetailBloc, ProductDetailState>(
          //   listener: (context, state) {
          //     if (state is ProductDetailErrorState) {
          //       Scaffold.of(context).showSnackBar(
          //         SnackBar(
          //           content: Text('error'),
          //         ),
          //       );
          //     }
          //   },
          //   child: BlocBuilder<ProductDetailBloc, ProductDetailState>(
          //     builder: (context, state) {
          //       if (state is ProductDetailInitialState) {
          //         return shimmer();
          //       } else if (state is ProductDetailLoadingState) {
          //         return shimmer();
          //       } else if (state is ProductDetailLoadedState) {
          //           productList = state.articles;
          //           print('ooopoooooooodproductListoooooooooooooooo  ${productList.length}');
          //          return Stack(
          //                 children: <Widget>[
          //                   _showContent(state.articles),
          //                   showCircularProgress(_isProgress, colors.primary),
          //                 ],
          //               );
          //       } else if (state is ProductDetailErrorState) {
          //         return Container(child: Text('error'));
          //       }
          //       return Container();
          //     },
          //   ),
          // )
      ?Stack(
              children: <Widget>[
                _showContent(),
                showCircularProgress(_isProgress, colors.primary),
              ],
            )
          : noInternet(context),
    );
  }

  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  Widget _slider() {
    double height = MediaQuery.of(context).size.height * .38;
    double statusBarHeight = MediaQuery.of(context).padding.top;

    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            PageRouteBuilder(
              // transitionDuration: Duration(seconds: 1),
              pageBuilder: (_, __, ___) => ProductPreview(
                pos: _curSlider,
                secPos: widget.secPos,
                index: widget.index,
                id: widget.model.id,
                imgList: sliderList,
                list: widget.list,
                video: widget.model.video,
                videoType: widget.model.videType,
                from: true,
              ),
            ));
      },
      child: Stack(
        children: <Widget>[
          Hero(
              tag: widget.list
                  ? "${widget.index}${widget.model.id}"
                  : "${sectionList[widget.secPos].productList[widget.index].id}${widget.secPos}${widget.index}",
              child: Container(
                height: height,
                width: double.infinity,
                child: PageView.builder(
                  itemCount: sliderList.length,
                  scrollDirection: Axis.horizontal,
                  controller: _pageController,
                  reverse: false,
                  onPageChanged: (index) {
                    if (mounted)
                      setState(() {
                        _curSlider = index;
                      });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return Stack(
                      children: [
                        FadeInImage(
                          image: NetworkImage(sliderList[index]),
                          placeholder: AssetImage(
                            "assets/images/sliderph.svg",
                          ),
                          height: height,
                          width: double.maxFinite,
                          fit: extendImg ? BoxFit.fill : BoxFit.contain,
                        ),
                        index == 1 ? playIcon() : Container()
                      ],
                    );
                  },
                ),
              )),
          Positioned.fill(
            child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: EdgeInsetsDirectional.only(bottom: 5),
                  child: Text(
                    "${_curSlider + 1}/${sliderList.length}",
                    style: Theme.of(context)
                        .textTheme
                        .caption
                        .copyWith(color: colors.primary),
                  ),
                  decoration: BoxDecoration(
                      color: colors.lightWhite,
                      borderRadius: BorderRadius.circular(5)),
                  padding: EdgeInsets.symmetric(horizontal: 5),
                )),
          ),
          indicatorImage(),
          Container(
            width: 40,
            alignment: AlignmentDirectional.centerStart,
            height: kToolbarHeight,
            margin: EdgeInsetsDirectional.only(top: statusBarHeight, start: 10),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                    color: colors.lightWhite,
                    offset: Offset(0, 0),
                    blurRadius: 30)
              ],
            ),
            child: Card(
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.keyboard_arrow_left, color: colors.primary),
                ),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: Container(
                margin: EdgeInsetsDirectional.only(top: statusBarHeight),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        color: colors.lightWhite,
                        offset: Offset(0, 0),
                        blurRadius: 30)
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                      top: 10.0, bottom: 10, end: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          child: Card(
                              elevation: 0,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Icon(
                                        Icons.share_outlined,
                                        color: colors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    onTap: () {
                                      createDynamicLink();
                                    }),
                              ))),
                      Container(
                          //  decoration: shadow(),
                          child: Card(
                              elevation: 0,
                              child: widget.model.isFavLoading
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                          height: 10,
                                          width: 10,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 0.7,
                                          )),
                                    )
                                  : Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Icon(
                                              widget.model.isFav == "0"
                                                  ? Icons.favorite_border
                                                  : Icons.favorite,
                                              color: colors.primary,
                                              size: 20,
                                            ),
                                          ),
                                          onTap: () {
                                            if (CUR_USERID != null) {
                                              widget.model.isFav == "0"
                                                  ?
                                                  //  _buildSetFav()
                                                  _setFav()
                                                  : _removeFav();
                                            } else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        Login()),
                                              );
                                            }
                                          }),
                                    ))),
                      Container(
                        //decoration: shadow(),
                        child: Card(
                          elevation: 0,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () async {
                              CUR_USERID == null
                                  ? Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Login(),
                                      ))
                                  : Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Cart(
                                            widget.updateHome, updateDetail),
                                      ));
                            },
                            child: new Stack(children: <Widget>[
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: SvgPicture.asset(
                                    'assets/images/noti_cart.svg',
                                  ),
                                ),
                              ),
                              (CUR_CART_COUNT != null &&
                                      CUR_CART_COUNT.isNotEmpty &&
                                      CUR_CART_COUNT != "0")
                                  ? new Positioned(
                                      top: 0.0,
                                      right: 5.0,
                                      bottom: 10,
                                      child: Container(
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: colors.primary
                                                  .withOpacity(0.5)),
                                          child: new Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(3),
                                              child: new Text(
                                                CUR_CART_COUNT,
                                                style: TextStyle(
                                                    fontSize: 7,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          )),
                                    )
                                  : Container()
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          )
        ],
      ),
    );
  }

  indicatorImage() {
    String indicator = widget.model.indicator;
    return Positioned.fill(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
          alignment: Alignment.bottomRight,
          child: indicator == "1"
              ? SvgPicture.asset("assets/images/vag.svg")
              : indicator == "2"
                  ? SvgPicture.asset("assets/images/nonvag.svg")
                  : Container()),
    ));
  }

  updateDetail() {
    if (mounted) setState(() {});
  }

  _rate() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RatingBarIndicator(
            rating: double.parse(widget.model.rating),
            itemBuilder: (context, index) => Icon(
              Icons.star,
              color: colors.primary,
            ),
            itemCount: 5,
            itemSize: 12.0,
            direction: Axis.horizontal,
          ),
          Text(
            " " + widget.model.rating,
            style: Theme.of(context)
                .textTheme
                .caption
                .copyWith(color: colors.lightBlack),
          ),
          Text(
            " | " + widget.model.noOfRating + " Ratings",
            style: Theme.of(context)
                .textTheme
                .caption
                .copyWith(color: colors.lightBlack),
          )
        ],
      ),
    );
  }

  _price(pos) {
    double price = double.parse(widget.model.prVarientList[pos].disPrice);
    if (price == 0) price = double.parse(widget.model.prVarientList[pos].price);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Text(CUR_CURRENCY + " " + price.toString(),
          style: Theme.of(context).textTheme.headline6),
    );
  }

  _offPrice(pos) {
    double price = double.parse(widget.model.prVarientList[pos].disPrice);

    if (price != 0) {
      double off = (double.parse(widget.model.prVarientList[pos].price) -
              double.parse(widget.model.prVarientList[pos].disPrice))
          .toDouble();
      off = off * 100 / double.parse(widget.model.prVarientList[pos].price);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: <Widget>[
            Text(
              CUR_CURRENCY + " " + widget.model.prVarientList[pos].price,
              style: Theme.of(context).textTheme.bodyText2.copyWith(
                  decoration: TextDecoration.lineThrough, letterSpacing: 0),
            ),
            Text(" | " + off.toStringAsFixed(2) + "% off",
                style: Theme.of(context)
                    .textTheme
                    .overline
                    .copyWith(color: colors.primary, letterSpacing: 0)),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  _title() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
      child: Text(
        widget.model.name,
        style: Theme.of(context)
            .textTheme
            .subtitle1
            .copyWith(color: colors.lightBlack),
      ),
    );
  }

  _desc() {
    return widget.model.desc.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Html(data: widget.model.desc),
          )
        : Container();
  }

  setSnackbar(String msg) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.black),
      ),
      backgroundColor: colors.white,
      elevation: 1.0,
    ));
  }

  _getVarient(int pos) {
    if (widget.model.type == "variable_product") {
      List<String> attrName =
          widget.model.prVarientList[pos].attr_name.split(',');
      List<String> attrValue =
          widget.model.prVarientList[pos].varient_value.split(',');
      String val = '';

      for (int i = 0; i < attrName.length; i++) {
        val = val + attrValue[i].length.toString() + " " + attrName[i];
      }

      return Column(
        children: [
          GestureDetector(
            child: ListTile(
              dense: true,
              title: Text(
                widget.model.prVarientList[pos].attr_name,
                style: TextStyle(color: colors.lightBlack),
              ),
              trailing: Icon(Icons.keyboard_arrow_right),
            ),
            onTap: _chooseVarient,
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  void _extraDetail() {
    showModalBottomSheet<dynamic>(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: ListView(shrinkWrap: true, children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _desc(),
                    widget.model.desc.isNotEmpty ? Divider() : Container(),
                    _attr(),
                    widget.model.attributeList.isNotEmpty
                        ? Divider()
                        : Container(),
                    _madeIn(),
                    _warrenty(),
                    _gaurantee(),
                    _otherDetail(widget.model.selVarient),
                    _cancleable(),
                  ],
                )
              ]),
            );
            //});
          });
        });
  }

  void _chooseVarient() {
    bool available;

    //selList--selected list
    //sinList---single attribute list for compare
    _selectedIndex.clear();
    if (widget.model.stockType == "0" || widget.model.stockType == "1") {
      if (widget.model.availability == "1") {
        available = true;

        _oldSelVarient = widget.model.selVarient;
      } else {
        available = false;
      }
    } else if (widget.model.stockType == "null") {
      available = true;

      _oldSelVarient = widget.model.selVarient;
    } else if (widget.model.stockType == "2") {
      if (widget.model.prVarientList[widget.model.selVarient].availability ==
          "1") {
        available = true;

        _oldSelVarient = widget.model.selVarient;
      } else {
        available = false;
      }
    }

    List<String> selList = widget
        .model.prVarientList[widget.model.selVarient].attribute_value_ids
        .split(",");

    for (int i = 0; i < widget.model.attributeList.length; i++) {
      List<String> sinList = widget.model.attributeList[i].id.split(',');

      for (int j = 0; j < sinList.length; j++) {
        if (selList.contains(sinList[j])) {
          _selectedIndex.insert(i, j);
        }
      }

      if (_selectedIndex.length == i) _selectedIndex.insert(i, null);
    }

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(
                      getTranslated(context, 'selectVarient'),
                      style: Theme.of(context).textTheme.headline6,
                    ),
                  ),
                  Divider(),
                  _title(),
                  _price(_oldSelVarient),
                  _offPrice(_oldSelVarient),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: widget.model.attributeList.length,
                    itemBuilder: (context, index) {
                      List<Widget> chips = new List();
                      List<String> att =
                          widget.model.attributeList[index].value.split(',');
                      List<String> attId =
                          widget.model.attributeList[index].id.split(',');
                      int varSelected;

                      List<String> wholeAtt = widget.model.attrIds.split(',');

                      for (int i = 0; i < att.length; i++) {
                        if (_selectedIndex[index] != null) if (wholeAtt
                            .contains(attId[i])) {
                          choiceChip = ChoiceChip(
                            selected: _selectedIndex.length > index
                                ? _selectedIndex[index] == i
                                : false,
                            label: Text(att[i],
                                style: TextStyle(color: colors.white)),
                            // backgroundColor: colors.colors.fontColor.withOpacity(0.45),
                            selectedColor: colors.grad2Color,
                            disabledColor: colors.grad2Color.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5))),
                            onSelected: att.length == 1
                                ? null
                                : (bool selected) {
                                    if (selected) if (mounted)
                                      setState(() {
                                        available = false;
                                        _selectedIndex[index] =
                                            selected ? i : null;
                                        List<int> selectedId =
                                            []; //list where user choosen item id is stored
                                        List<bool> check = [];
                                        for (int i = 0;
                                            i <
                                                widget
                                                    .model.attributeList.length;
                                            i++) {
                                          List<String> attId = widget
                                              .model.attributeList[i].id
                                              .split(',');

                                          if (_selectedIndex[i] != null)
                                            selectedId.add(int.parse(
                                                attId[_selectedIndex[i]]));
                                        }
                                        check.clear();
                                        List<String> sinId;
                                        findMatch:
                                        for (int i = 0;
                                            i <
                                                widget
                                                    .model.prVarientList.length;
                                            i++) {
                                          sinId = widget.model.prVarientList[i]
                                              .attribute_value_ids
                                              .split(",");

                                          for (int j = 0;
                                              j < selectedId.length;
                                              j++) {
                                            if (sinId.contains(
                                                selectedId[j].toString())) {
                                              check.add(true);

                                              if (selectedId.length ==
                                                      sinId.length &&
                                                  check.length ==
                                                      selectedId.length) {
                                                varSelected = i;
                                                break findMatch;
                                              }
                                            } else {
                                              print(
                                                  'match****not match==braek**$j');
                                              break;
                                            }
                                          }
                                        }

                                        if (selectedId.length == sinId.length &&
                                            check.length == selectedId.length) {
                                          if (widget.model.stockType == "0" ||
                                              widget.model.stockType == "1") {
                                            if (widget.model.availability ==
                                                "1") {
                                              available = true;

                                              _oldSelVarient = varSelected;
                                            } else {
                                              available = false;
                                            }
                                          } else if (widget.model.stockType ==
                                              "null") {
                                            available = true;

                                            _oldSelVarient = varSelected;
                                          } else if (widget.model.stockType ==
                                              "2") {
                                            if (widget
                                                    .model
                                                    .prVarientList[varSelected]
                                                    .availability ==
                                                "1") {
                                              available = true;

                                              _oldSelVarient = varSelected;
                                            } else {
                                              available = false;
                                            }
                                          }
                                        } else {
                                          available = false;
                                        }
                                        if (widget
                                                .model
                                                .prVarientList[_oldSelVarient]
                                                .images
                                                .length >
                                            0) {
                                          int oldVarTotal = 0;
                                          if (_oldSelVarient > 0)
                                            for (int i = 0;
                                                i < _oldSelVarient;
                                                i++) {
                                              oldVarTotal = oldVarTotal +
                                                  widget.model.prVarientList[i]
                                                      .images.length;
                                            }
                                          int p =
                                              widget.model.otherImage.length +
                                                  1 +
                                                  oldVarTotal;

                                          _pageController.jumpToPage(p);
                                        }

                                        print(
                                            "selected list****${selectedId.toString()}");
                                      });
                                  },
                          );

                          chips.add(Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: choiceChip));
                        }
                      }

                      String value = _selectedIndex[index] != null &&
                              _selectedIndex[index] <= att.length
                          ? att[_selectedIndex[index]]
                          : getTranslated(context, 'VAR_SEL').substring(
                              2, getTranslated(context, 'VAR_SEL').length);
                      return chips.length > 0
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    widget.model.attributeList[index].name +
                                        " : " +
                                        value,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  new Wrap(
                                    children: chips.map<Widget>((Widget chip) {
                                      return Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: chip,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            )
                          : Container();
                    },
                  ),
                  available == false
                      ? Center(
                          child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            "This varient doesn't available.",
                            style: TextStyle(color: Colors.red),
                          ),
                        ))
                      : Container(),
                  CupertinoButton(
                    padding: EdgeInsets.all(0),
                    child: Container(
                        alignment: FractionalOffset.center,
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: available
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                      colors.grad1Color,
                                      colors.grad2Color
                                    ],
                                  stops: [
                                      0,
                                      1
                                    ])
                              : null,
                          color: available ? null : colors.disableColor,
                        ),
                        child: Text(getTranslated(context, 'APPLY'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.button.copyWith(
                                  color: colors.white,
                                ))),
                    onPressed: available ? applyVarient : null,
                  )
                ],
              ),
            );
          });
        });
  }

  applyVarient() {
    Navigator.of(context).pop();
    if (mounted)
      setState(() {
        widget.model.selVarient = _oldSelVarient;
      });
  }

  Future<void> addToCart(bool intent) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null) {
        try {
          if (mounted) if (mounted)
            setState(() {
              _isProgress = true;
            });

          var parameter = {
            USER_ID: CUR_USERID,
            PRODUCT_VARIENT_ID:
                widget.model.prVarientList[widget.model.selVarient].id,
            QTY: (int.parse(widget.model.prVarientList[widget.model.selVarient]
                        .cartCount) +
                    1)
                .toString(),
          };

          Response response =
              await post(manageCartApi, body: parameter, headers: headers)
                  .timeout(Duration(seconds: timeOut));

          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];
            CUR_CART_COUNT = data['cart_count'];
            if (intent)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Cart(widget.updateHome, updateDetail),
                ),
              );
          } else {
            setSnackbar(msg);
          }
          if (mounted)
            setState(() {
              _isProgress = false;
            });

          widget.updateParent();
          widget.updateHome();
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg'));
          if (mounted)
            setState(() {
              _isProgress = false;
            });
        }
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  Future<void> getReview() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          PRODUCT_ID: widget.model.id,
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
        };

        Response response =
            await post(getRatingApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          total = int.parse(getdata["total"]);

          if ((offset) < total) {
            var data = getdata["data"];
            reviewList =
                (data as List).map((data) => new User.forReview(data)).toList();

            offset = offset + perPage;
          }
        } else {
          if (msg != "No ratings found !") setSnackbar(msg);
          isLoadingmore = false;
        }
        if (mounted) if (mounted)
          setState(() {
            _isLoading = false;
          });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'));
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }



///setting fav ........................19.4.21
///// modified 20-4-21........working but icon not changing

 // ignore: unused_element
 Widget _buildSetFav() {
    return Container(
      child: BlocListener<FavBloc, FavState>(
        listener: (context, state) {
          if (state is AddToFavFailed) {
            Scaffold.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
              ),
            );
          }
        },
        child: BlocBuilder<FavBloc, FavState>(
          builder: (context, state) {
            if (state is FavInitialState) {
               setState(() {
      sampleBloc.add(
        OnAddToFav(
          userId: CUR_USERID,
          productId: widget.model.id,
          )
      );
      print(
          '///////////77777799......$CUR_USERID......${widget.model.id}....');
    });
            } else if (state is FavSettingFav) {
          setState(() {
            widget.model.isFavLoading = true;
          });
            } else if (state is FavSetFav) {
          setState(() {
            widget.model.isFavLoading = false;
          });
              // ignore: unnecessary_statements
            widget.model.isFav = "1";
             widget.updateParent();
            }else if (state is AddToFavFailed) {
              return Container(child: Text(state.message));
            }
            return Container();
          },
        ),
      ),
    );
  }

  _setFav() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted)
          setState(() {
            widget.model.isFavLoading = true;
          });

        var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: widget.model.id};
        Response response =
            await post(setFavoriteApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          widget.model.isFav = "1";
          widget.updateParent();

          //  home.updateHomepage();
        } else {
          setSnackbar(msg);
        }

        if (mounted)
          setState(() {
            widget.model.isFavLoading = false;
          });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'));
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  _removeFav() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted)
          setState(() {
            widget.model.isFavLoading = true;
          });

        var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: widget.model.id};
        Response response =
            await post(removeFavApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          widget.model.isFav = "0";
          widget.updateParent();

          favList.removeWhere((item) =>
              item.productList[0].prVarientList[0].id ==
              widget.model.prVarientList[0].id);
        } else {
          setSnackbar(msg);
        }

        if (mounted)
          setState(() {
            widget.model.isFavLoading = false;
          });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'));
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  _showContent() {
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            controller: notificationcontroller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Card(
                  elevation: 0,
                  margin: EdgeInsets.all(0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _slider(),
                      _title(),
                      _rate(),
                      _price(widget.model.selVarient),
                      _offPrice(widget.model.selVarient),
                      _shortDesc(),
                      widget.model.type == "variable_product"
                          ? Divider()
                          : Container(),
                      _getVarient(widget.model.selVarient),
                      Divider(),
                      _specification(),
                      Divider(),
//if you want to remove discount and coupon then just double slash below line
                      _discountCoupon(),
                      if (widget.model.tagList != null &&
                          widget.model.tagList.isNotEmpty)
                        Divider(),
                      _tags()
                    ],
                  ),
                ),
                reviewList.length > 0
                    ? Card(
                        elevation: 0,
                        margin:
                            EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _reviewTitle(),
                            _review(),
                            InkWell(
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(
                                  getTranslated(context, 'VIEW_ALL'),
                                  style: TextStyle(color: colors.primary),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          RatingReview(id: widget.model.id)),
                                );
                              },
                            )
                          ],
                        ),
                      )
                    : Container(),
                productList.length > 0
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          getTranslated(context, 'MORE_PRODUCT'),
                          style: Theme.of(context).textTheme.subtitle1,
                        ),
                      )
                    : Container(),
                GridView.count(
                    padding: EdgeInsetsDirectional.only(top: 5),
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    childAspectRatio: 1.0,
                    physics: NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 0,
                    crossAxisSpacing: 0,
                    children: List.generate(
                      productList.length,
                      (index) {
                        Product item;
                        try {
                          item =
                              productList.isEmpty ? null : productList[index];
                          if (notificationisloadmore &&
                              index == (productList.length - 1) &&
                              notificationcontroller.position.pixels <= 0) {
                            getProduct();
                          }
                        } on Exception catch (_) {}

                        return item == null
                            ? Container()
                            : productItem(index, index % 2 == 0 ? true : false);
                      },
                    )),
              ],
            ),
          ),
        ),
        widget.model.availability == "1" || widget.model.stockType == "null"
            ? Row(
                children: [
                  Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: colors.white,
                      boxShadow: [
                        BoxShadow(color: colors.black26, blurRadius: 10)
                      ],
                    ),
                    width: deviceWidth * 0.5,
                    child: InkWell(
                      onTap: () {
                        //here
                        addToCart(false);
                      },
                      child: Center(
                          child: Text(
                        getTranslated(context, 'ADD_CART'),
                        style: Theme.of(context).textTheme.button.copyWith(
                            fontWeight: FontWeight.bold, color: colors.primary),
                      )),
                    ),
                  ),
                  Container(
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colors.grad1Color, colors.grad2Color],
                          stops: [0, 1]),
                      boxShadow: [
                        BoxShadow(color: colors.black26, blurRadius: 10)
                      ],
                    ),
                    width: deviceWidth * 0.5,
                    child: InkWell(
                      onTap: () {
                        //here
                        addToCart(true);
                      },
                      child: Center(
                          child: Text(
                        getTranslated(context, 'BUYNOW'),
                        style: Theme.of(context).textTheme.button.copyWith(
                            fontWeight: FontWeight.bold, color: colors.white),
                      )),
                    ),
                  ),
                ],
              )
            : Container(
                height: 55,
                decoration: BoxDecoration(
                  color: colors.white,
                  boxShadow: [BoxShadow(color: colors.black26, blurRadius: 10)],
                ),
                child: Center(
                    child: Text(
                  getTranslated(context, 'OUT_OF_STOCK_LBL'),
                  style: Theme.of(context)
                      .textTheme
                      .button
                      .copyWith(fontWeight: FontWeight.bold, color: Colors.red),
                )),
              ),
      ],
    );
  }

  _madeIn() {
    String madeIn = widget.model.madein;

    return madeIn != null && madeIn.isNotEmpty
        ? Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ListTile(
              trailing: Text(madeIn),
              dense: true,
              title: Text(
                'Made In',
                style: Theme.of(context).textTheme.subtitle2,
              ),
            ),
          )
        : Container();
  }

  Widget productItem(int index, bool pad) {
    String offPer;
    double price = double.parse(productList[index].prVarientList[0].disPrice);
    if (price == 0) {
      price = double.parse(productList[index].prVarientList[0].price);
    } else {
      double off =
          double.parse(productList[index].prVarientList[0].price) - price;
      offPer = ((off * 100) /
              double.parse(productList[index].prVarientList[0].price))
          .toStringAsFixed(2);
    }

    double width = deviceWidth * 0.5;

    return Card(
      elevation: 0.2,
      margin: EdgeInsetsDirectional.only(bottom: 5, end: pad ? 5 : 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5)),
                  child: Hero(
                    tag: "$index${productList[index].id}",
                    child: FadeInImage(
                      image: NetworkImage(productList[index].image),
                      height: double.maxFinite,
                      width: double.maxFinite,
                      fit: extendImg ? BoxFit.fill : BoxFit.contain,
                      //errorWidget: (context, url, e) => placeHolder(width),
                      placeholder: placeHolder(width),
                    ),
                  )),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: 5.0, top: 5, bottom: 5),
              child: Text(
                productList[index].name,
                style: Theme.of(context)
                    .textTheme
                    .caption
                    .copyWith(color: colors.lightBlack),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(" " + CUR_CURRENCY + " " + price.toString(),
                style: TextStyle(
                    color: colors.fontColor, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: 5.0, bottom: 5, top: 3),
              child:
                  double.parse(productList[index].prVarientList[0].disPrice) !=
                          0
                      ? Row(
                          children: <Widget>[
                            Text(
                              double.parse(productList[index]
                                          .prVarientList[0]
                                          .disPrice) !=
                                      0
                                  ? CUR_CURRENCY +
                                      "" +
                                      productList[index].prVarientList[0].price
                                  : "",
                              style: Theme.of(context)
                                  .textTheme
                                  .overline
                                  .copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      letterSpacing: 0),
                            ),
                            Text(" | " + "-$offPer%",
                                style: Theme.of(context)
                                    .textTheme
                                    .overline
                                    .copyWith(
                                        color: colors.primary,
                                        letterSpacing: 0)),
                          ],
                        )
                      : Container(
                          height: 5,
                        ),
            )
          ],
        ),
        onTap: () {
          Product model = productList[index];
          notificationoffset = 0;

          Navigator.push(
            context,
            PageRouteBuilder(
                // transitionDuration: Duration(seconds: 1),
                pageBuilder: (_, __, ___) => ProductDetail(
                    model: model,
                    updateParent: widget.updateParent,
                    secPos: widget.secPos,
                    index: index,
                    updateHome: widget.updateHome,
                    list: true
                    //  title: sectionList[secPos].title,
                    )),
          );
        },
      ),
    );
  }

  Widget _review() {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            itemCount: reviewList.length >= 2 ? 2 : reviewList.length,
            physics: NeverScrollableScrollPhysics(),
            separatorBuilder: (BuildContext context, int index) => Divider(),
            itemBuilder: (context, index) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reviewList[index].username,
                        style: TextStyle(fontWeight: FontWeight.w400),
                      ),
                      Spacer(),
                      Text(
                        reviewList[index].date,
                        style:
                            TextStyle(color: colors.lightBlack, fontSize: 11),
                      )
                    ],
                  ),
                  RatingBarIndicator(
                    rating: double.parse(reviewList[index].rating),
                    itemBuilder: (context, index) => Icon(
                      Icons.star,
                      color: colors.primary,
                    ),
                    itemCount: 5,
                    itemSize: 12.0,
                    direction: Axis.horizontal,
                  ),
                  reviewList[index].comment != null &&
                          reviewList[index].comment.isNotEmpty
                      ? Text(reviewList[index].comment ?? '')
                      : Container(),
                  reviewImage(index),
                ],
              );
            });
  }



  Future getProduct() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (notificationisloadmore) {
          if (mounted)
            setState(() {
              notificationisloadmore = false;
              notificationisgettingdata = true;
              if (notificationoffset == 0) {
                productList = new List<Product>();
              }
            });

          var parameter = {
            CATID: widget.model.categoryId,
            LIMIT: perPage.toString(),
            OFFSET: notificationoffset.toString(),
            ID: widget.model.id,
            IS_SIMILAR: "1"
          };

          if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID;

          Response response =
              await post(getProductApi, headers: headers, body: parameter)
                  .timeout(Duration(seconds: timeOut));

          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String msg = getdata["message"];
print(msg);
          notificationisgettingdata = false;
          if (notificationoffset == 0) notificationisnodata = error;

          if (!error) {
            if (mounted) {
              new Future.delayed(
                  Duration.zero,
                  () => setState(() {
                        List mainlist = getdata['data'];

                        if (mainlist.length != 0) {
                          List<Product> items = new List<Product>();
                          List<Product> allitems = new List<Product>();

                          items.addAll(mainlist
                              .map((data) => new Product.fromJson(data))
                              .toList());

                          allitems.addAll(items);

                          for (Product item in items) {
                            productList
                                .where((i) => i.id == item.id)
                                .map((obj) {
                              allitems.remove(item);
                              return obj;
                            }).toList();
                          }
                          productList.addAll(allitems);
                          notificationisloadmore = true;
                          notificationoffset = notificationoffset + perPage;
                        } else {
                          notificationisloadmore = false;
                        }
                      }));
            }
          } else {
            notificationisloadmore = false;
            if (mounted) if (mounted) setState(() {});
          }
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'));
        if (mounted)
          setState(() {
            notificationisloadmore = false;
          });
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  _otherDetail(int pos) {
    String returnable = widget.model.isReturnable;
    if (returnable == "1")
      returnable = RETURN_DAYS + " Days";
    else
      returnable = "No";
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: ListTile(
        trailing: Text(returnable),
        dense: true,
        title: Text(
          'Returnable',
          style: Theme.of(context).textTheme.subtitle2,
        ),
      ),
    );
  }

  _cancleable() {
    String cancleable = widget.model.isCancelable;
    if (cancleable == "1")
      cancleable = "Till " + widget.model.cancleTill;
    else
      cancleable = "No";
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: ListTile(
        trailing: Text(cancleable),
        dense: true,
        title: Text(
          'Cancellable',
          style: Theme.of(context).textTheme.subtitle2,
        ),
      ),
    );
  }

  _specification() {
    return GestureDetector(
      child: ListTile(
        dense: true,
        title: Text(
          getTranslated(context, 'SPECIFICATION'),
          style: TextStyle(color: colors.lightBlack),
        ),
        trailing: Icon(Icons.keyboard_arrow_right),
      ),
      onTap: _extraDetail,
    );
  }

  _discountCoupon() {
    return GestureDetector(
      child: ListTile(
        dense: true,
        title: Text(
          getTranslated(context, 'DISCOUPON'),
          style: TextStyle(color: colors.lightBlack),
        ),
        trailing: Icon(Icons.keyboard_arrow_right),
        subtitle: Text(
          getTranslated(context, 'COMINGSOON'),
          style: TextStyle(color: colors.primary),
        ),
      ),
    );
  }

  _reviewTitle() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
        child: Row(
          children: [
            Text(
              getTranslated(context, 'CUSTOMER_REVIEW_LBL') + " ($total)",
              style: Theme.of(context).textTheme.subtitle2.copyWith(
                  color: colors.lightBlack, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text(
              widget.model.rating + "/5 ",
              style: Theme.of(context)
                  .textTheme
                  .caption
                  .copyWith(color: colors.lightBlack2),
            ),
            RatingBarIndicator(
              rating: double.parse(widget.model.rating),
              itemBuilder: (context, index) => Icon(
                Icons.star,
                color: colors.primary,
              ),
              itemCount: 5,
              itemSize: 12.0,
              direction: Axis.horizontal,
            ),
          ],
        ));
  }

  reviewImage(int i) {
    return Container(
      height: reviewList[i].imgList.length > 0 ? 50 : 0,
      child: ListView.builder(
        itemCount: reviewList[i].imgList.length,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Padding(
            padding:
                const EdgeInsetsDirectional.only(end: 10, bottom: 5.0, top: 5),
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => ProductPreview(
                        pos: index,
                        secPos: widget.secPos,
                        index: widget.index,
                        id: '$index${reviewList[i].id}',
                        imgList: reviewList[i].imgList,
                        list: true,
                        from: false,
                      ),
                    ));
              },
              child: Hero(
                tag: "$index${reviewList[i].id}",
                child: new ClipRRect(
                  borderRadius: BorderRadius.circular(5.0),
                  child: new FadeInImage(
                    image: NetworkImage(reviewList[i].imgList[index]),
                    height: 50.0,
                    width: 50.0,
                    placeholder: placeHolder(50),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  _shortDesc() {
    return widget.model.shortDescription.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.model.shortDescription,
              style: Theme.of(context).textTheme.subtitle2,
            ),
          )
        : Container();
  }

  _attr() {
    return widget.model.attributeList.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.model.attributeList.length,
              itemBuilder: (context, i) {
                return ListTile(
                  trailing: Text(widget.model.attributeList[i].value),
                  dense: true,
                  title: Text(
                    widget.model.attributeList[i].name,
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                );
              },
            ),
          )
        : Container();
  }

  Future<void> getShare() async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: deepLinkUrlPrefix,
      link: Uri.parse(
          'https://$deepLinkName/?index=${widget.index}&secPos=${widget.secPos}&list=${widget.list}&id=${widget.model.id}'),
      androidParameters: AndroidParameters(
        packageName: packageName,
        minimumVersion: 1,
      ),
      iosParameters: IosParameters(
        bundleId: iosPackage,
        minimumVersion: '1',
        appStoreId: appStoreId,
      ),
    );

    final Uri longDynamicUrl = await parameters.buildUrl();
    shortenedLink = await DynamicLinkParameters.shortenUrl(
      longDynamicUrl,
      new DynamicLinkParametersOptions(
          shortDynamicLinkPathLength: ShortDynamicLinkPathLength.unguessable),
    );
    new Future.delayed(Duration.zero, () {
      shareLink =
          "\n$appName\n${getTranslated(context, 'APPFIND')}$androidLink$packageName\n${getTranslated(context, 'IOSLBL')}\n$iosLink$iosPackage";
    });
  }

  _warrenty() {
    String warranty = widget.model.warranty;

    return warranty != null && warranty.isNotEmpty
        ? Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ListTile(
              trailing: Text(warranty),
              dense: true,
              title: Text(
                'Warranty',
                style: Theme.of(context).textTheme.subtitle2,
              ),
            ),
          )
        : Container();
  }

  playIcon() {
    return Align(
        alignment: Alignment.center,
        child: (widget.model.videType != null &&
                widget.model.video != null &&
                widget.model.video.isNotEmpty &&
                widget.model.video != "")
            ? Icon(
                Icons.play_circle_fill_outlined,
                color: colors.primary,
                size: 35,
              )
            : Container());
  }

  _tags() {
    if (widget.model.tagList != null) {
      List<Widget> chips = new List();
      for (int i = 0; i < widget.model.tagList.length; i++) {
        tagChip = ChoiceChip(
          selected: false,
          label: Text(widget.model.tagList[i],
              style: TextStyle(color: colors.white)),
          backgroundColor: colors.primary,
          // selectedColor: colors.grad2Color,
          // disabledColor: colors.grad2Color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5))),
          onSelected: (bool selected) {
            if (selected) if (mounted)
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      name: widget.model.tagList[i],
                      //id: catList[index].id,
                      updateHome: widget.updateHome,
                      tag: true,
                    ),
                  ));
          },
        );

        chips.add(Padding(
            padding: EdgeInsets.symmetric(horizontal: 5), child: tagChip));
      }

      return Wrap(
        children: chips.map<Widget>((Widget chip) {
          return Padding(
            padding: const EdgeInsets.all(2.0),
            child: chip,
          );
        }).toList(),
      );
    } else {
      return Container();
    }
  }

  _gaurantee() {
    String gaurantee = widget.model.gurantee;
print("gurantee***$gaurantee");

    return gaurantee != null && gaurantee.isNotEmpty
        ? Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ListTile(
              trailing: Text(gaurantee),
              dense: true,
              title: Text(
                'Gurantee',
                style: Theme.of(context).textTheme.subtitle2,
              ),
            ),
          )
        : Container();
  }
}
