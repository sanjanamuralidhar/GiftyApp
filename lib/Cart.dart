import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:giftty/Helper/Constant.dart';
import 'package:giftty/Helper/Session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
import 'package:paytm/paytm.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'Add_Address.dart';
import 'Helper/AppBtn.dart';
import 'Helper/Color.dart';
import 'Helper/SimBtn.dart';
import 'Helper/String.dart';
import 'Helper/Stripe_Service.dart';
import 'Home.dart';
import 'Manage_Address.dart';
import 'Model/Section_Model.dart';
import 'Model/User.dart';
import 'Order_Success.dart';
import 'Payment.dart';
import 'PaypalWebviewActivity.dart';
import 'package:giftty/bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Cart extends StatefulWidget {
  final Function updateHome, updateParent;

  Cart(this.updateHome, this.updateParent);

  @override
  State<StatefulWidget> createState() => StateCart();
}

List<User> addressList = [];
List<Section_Model> cartList = [];
double totalPrice = 0, oriPrice = 0, delCharge = 0, taxAmt = 0, taxPer = 0;
int selectedAddress = 0;
String latitude,
    longitude,
    selAddress,
    payMethod = '',
    payIcon = '',
    selTime,
    selDate,
    promocode;
bool isTimeSlot, isPromoValid = false, isUseWallet = false, isPayLayShow = true;
int selectedTime, selectedDate, selectedMethod;
double promoAmt = 0;
double remWalBal, usedBal = 0;
String razorpayId,
    paystackId,
    stripeId,
    stripeSecret,
    stripeMode = "test",
    stripeCurCode,
    stripePayId,
    paytmMerId ,
    paytmMerKey;
bool payTesting = true;

class StateCart extends State<Cart> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isProgress = false;
  final GlobalKey<ScaffoldState> _checkscaffoldKey =
      new GlobalKey<ScaffoldState>();

  bool _isCartLoad = true, _isSaveLoad = true;
  HomePage home;
  Animation buttonSqueezeanimation;
  AnimationController buttonController;
  bool _isNetworkAvail = true;

  List<TextEditingController> _controller = [];
  var items;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  List<Section_Model> saveLaterList = [];
  String msg;
  bool _isLoading = true;
  Razorpay _razorpay;
  TextEditingController promoC = new TextEditingController();
  StateSetter checkoutState;
  CategoryBloc categoryBloc;
  SliderBloc sliderBloc;
  SectionBloc sectionBloc;

  @override
  void initState() {
    super.initState();
    categoryBloc = BlocProvider.of<CategoryBloc>(context);
    categoryBloc.add(FetchCategoryEvent());
    sliderBloc = BlocProvider.of<SliderBloc>(context);
    sliderBloc.add(FetchSliderEvent());
    sectionBloc = BlocProvider.of<SectionBloc>(context);
    sectionBloc.add(FetchSectionEvent());
    totalPrice = 0;
    oriPrice = 0;
    taxAmt = 0;
    taxPer = 0;
    delCharge = 0;
    cartList.clear();
    _getCart("0");
    _getSaveLater("1");
    home = new HomePage(widget.updateHome,categoryBloc,sliderBloc,sectionBloc);
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

  Future<Null> _refresh() {
    if (mounted)
      setState(() {
        _isCartLoad = true;
        _isSaveLoad = true;
      });
    totalPrice = 0;
    oriPrice = 0;
    taxAmt = 0;
    taxPer = 0;
    delCharge = 0;
    cartList.clear();
    _getCart("0");
    return _getSaveLater("1");
  }

  @override
  void dispose() {
    buttonController.dispose();
    for (int i = 0; i < _controller.length; i++) _controller[i].dispose();
    super.dispose();
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
    return Scaffold(
        key: _scaffoldKey,
        appBar: getAppBar(getTranslated(context, 'CART'), context),
        body: _isNetworkAvail
            ? Stack(
                children: <Widget>[
                  _showContent(),
                  showCircularProgress(_isProgress, colors.primary),
                ],
              )
            : noInternet(context));
  }

  Widget listItem(int index) {
    int selectedPos = 0;
    for (int i = 0;
        i < cartList[index].productList[0].prVarientList.length;
        i++) {
      if (cartList[index].varientId ==
          cartList[index].productList[0].prVarientList[i].id) selectedPos = i;
    }

    double price = double.parse(
        cartList[index].productList[0].prVarientList[selectedPos].disPrice);
    if (price == 0)
      price = double.parse(
          cartList[index].productList[0].prVarientList[selectedPos].price);

    cartList[index].perItemPrice = price.toString();
    cartList[index].perItemTotal =
        (price * double.parse(cartList[index].qty)).toString();

    if (_controller.length < index + 1)
      _controller.add(new TextEditingController());

    _controller[index].text = cartList[index].qty;

    items = new List<String>.generate(
        cartList[index].productList[0].totalAllow != null
            ? int.parse(cartList[index].productList[0].totalAllow)
            : 10,
        (i) => (i + 1).toString());

    return Card(
      elevation: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: <Widget>[
            Hero(
                tag: "$index${cartList[index].productList[0].id}",
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(7.0),
                    child: FadeInImage(
                      image: NetworkImage(cartList[index].productList[0].image),
                      height: 80.0,
                      width: 80.0,
                      fit: extendImg ? BoxFit.fill : BoxFit.contain,
                      placeholder: placeHolder(80),
                    ))),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(top: 5.0),
                            child: Text(
                              cartList[index].productList[0].name,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle2
                                  .copyWith(color: colors.lightBlack),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                start: 8.0, end: 8, bottom: 8),
                            child: Icon(
                              Icons.close,
                              size: 15,
                              color: colors.fontColor,
                            ),
                          ),
                          onTap: () {
                            if (_isProgress == false)
                              removeFromCart(index, true, cartList, false);
                          },
                        )
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          double.parse(cartList[index]
                                      .productList[0]
                                      .prVarientList[selectedPos]
                                      .disPrice) !=
                                  0
                              ? CUR_CURRENCY +
                                  "" +
                                  cartList[index]
                                      .productList[0]
                                      .prVarientList[selectedPos]
                                      .price
                              : "",
                          style: Theme.of(context).textTheme.overline.copyWith(
                              decoration: TextDecoration.lineThrough,
                              letterSpacing: 0.7),
                        ),
                        Text(
                          " " + CUR_CURRENCY + " " + price.toString(),
                          style: TextStyle(
                              color: colors.fontColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    cartList[index].productList[0].availability == "1" ||
                            cartList[index].productList[0].stockType == "null"
                        ? Row(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  GestureDetector(
                                    child: Container(
                                      padding: EdgeInsets.all(2),
                                      margin: EdgeInsetsDirectional.only(
                                          end: 8, top: 8, bottom: 8),
                                      child: Icon(
                                        Icons.remove,
                                        size: 14,
                                        color: colors.fontColor,
                                      ),
                                      decoration: BoxDecoration(
                                          color: colors.lightWhite,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(3))),
                                    ),
                                    onTap: () {
                                      if (_isProgress == false)
                                        removeFromCart(
                                            index, false, cartList, false);
                                    },
                                  ),
                                  Container(
                                    width: 40,
                                    height: 20,
                                    child: Stack(
                                      children: [
                                        TextField(
                                          textAlign: TextAlign.center,
                                          readOnly: true,
                                          style: TextStyle(
                                            fontSize: 10,
                                          ),
                                          controller: _controller[index],
                                          decoration: InputDecoration(
                                            contentPadding: EdgeInsets.all(5.0),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: colors.fontColor,
                                                  width: 0.5),
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: colors.fontColor,
                                                  width: 0.5),
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                            ),
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          tooltip: '',
                                          icon: const Icon(
                                            Icons.arrow_drop_down,
                                            size: 1,
                                          ),
                                          onSelected: (String value) {
                                            if (_isProgress == false)
                                              addToCart(index, value);
                                          },
                                          itemBuilder: (BuildContext context) {
                                            return items
                                                .map<PopupMenuItem<String>>(
                                                    (String value) {
                                              return new PopupMenuItem(
                                                  child: new Text(value),
                                                  value: value);
                                            }).toList();
                                          },
                                        ),
                                      ],
                                    ),
                                  ), // ),

                                  GestureDetector(
                                    child: Container(
                                      padding: EdgeInsets.all(2),
                                      margin: EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.add,
                                        size: 14,
                                        color: colors.fontColor,
                                      ),
                                      decoration: BoxDecoration(
                                          color: colors.lightWhite,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(3))),
                                    ),
                                    onTap: () {
                                      if (_isProgress == false)
                                        addToCart(
                                            index,
                                            (int.parse(cartList[index].qty) + 1)
                                                .toString());
                                    },
                                  )
                                ],
                              ),
                              GestureDetector(
                                child: Container(
                                  margin: EdgeInsetsDirectional.only(start: 8),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: colors.lightWhite,
                                      borderRadius: new BorderRadius.all(
                                          const Radius.circular(4.0))),
                                  child: Text(
                                    getTranslated(context, 'SAVEFORLATER_BTN'),
                                    style: TextStyle(
                                        color: colors.fontColor, fontSize: 11),
                                  ),
                                ),
                                onTap: () {
                                  saveForLater(
                                      cartList[index].varientId,
                                      "1",
                                      cartList[index].qty,
                                      double.parse(
                                          cartList[index].perItemTotal),
                                      cartList[index]);
                                },
                              ),
                            ],
                          )
                        : Container(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget cartItem(int index) {
    int selectedPos = 0;
    for (int i = 0;
        i < cartList[index].productList[0].prVarientList.length;
        i++) {
      if (cartList[index].varientId ==
          cartList[index].productList[0].prVarientList[i].id) selectedPos = i;
    }

    double price = double.parse(
        cartList[index].productList[0].prVarientList[selectedPos].disPrice);
    if (price == 0)
      price = double.parse(
          cartList[index].productList[0].prVarientList[selectedPos].price);

    cartList[index].perItemPrice = price.toString();
    cartList[index].perItemTotal =
        (price * double.parse(cartList[index].qty)).toString();

    items = new List<String>.generate(
        cartList[index].productList[0].totalAllow != null
            ? int.parse(cartList[index].productList[0].totalAllow)
            : 10,
        (i) => (i + 1).toString());

    _controller[index].text = cartList[index].qty;

    double taxAmt = ((double.parse(cartList[index].perItemTotal) *
            double.parse(cartList[index].productList[0].tax)) /
        100);

    return Card(
      elevation: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: <Widget>[
                Hero(
                    tag: "$index${cartList[index].productList[0].id}",
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(7.0),
                        child: FadeInImage(
                          image: NetworkImage(
                              cartList[index].productList[0].image),
                          height: 80.0,
                          width: 80.0,
                          fit: extendImg ? BoxFit.fill : BoxFit.contain,
                          // errorWidget: (context, url, e) => placeHolder(60),
                          placeholder: placeHolder(80),
                        ))),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(top: 5.0),
                                child: Text(
                                  cartList[index].productList[0].name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2
                                      .copyWith(color: colors.lightBlack),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            GestureDetector(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 8.0, end: 8, bottom: 8),
                                child: Icon(
                                  Icons.close,
                                  size: 13,
                                  color: colors.fontColor,
                                ),
                              ),
                              onTap: () {
                                if (_isProgress == false)
                                  removeFromCartCheckout(index, true);
                              },
                            )
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Text(
                              double.parse(cartList[index]
                                          .productList[0]
                                          .prVarientList[selectedPos]
                                          .disPrice) !=
                                      0
                                  ? CUR_CURRENCY +
                                      "" +
                                      cartList[index]
                                          .productList[0]
                                          .prVarientList[selectedPos]
                                          .price
                                  : "",
                              style: Theme.of(context)
                                  .textTheme
                                  .overline
                                  .copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      letterSpacing: 0.7),
                            ),
                            Text(
                              " " + CUR_CURRENCY + " " + price.toString(),
                              style: TextStyle(
                                  color: colors.fontColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        cartList[index].productList[0].availability == "1" ||
                                cartList[index].productList[0].stockType ==
                                    "null"
                            ? Row(
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      GestureDetector(
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          margin: EdgeInsetsDirectional.only(
                                              end: 8, top: 8, bottom: 8),
                                          child: Icon(
                                            Icons.remove,
                                            size: 12,
                                            color: colors.fontColor,
                                          ),
                                          decoration: BoxDecoration(
                                              color: colors.lightWhite,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(3))),
                                        ),
                                        onTap: () {
                                          if (_isProgress == false)
                                            removeFromCartCheckout(
                                                index, false);
                                        },
                                      ),

                                      Container(
                                        width: 40,
                                        height: 20,
                                        child: Stack(
                                          children: [
                                            TextField(
                                              textAlign: TextAlign.center,
                                              readOnly: true,
                                              style: TextStyle(
                                                fontSize: 10,
                                              ),
                                              controller: _controller[index],
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    EdgeInsets.all(5.0),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: colors.fontColor,
                                                      width: 0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: colors.fontColor,
                                                      width: 0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.0),
                                                ),
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              tooltip: '',
                                              icon: const Icon(
                                                Icons.arrow_drop_down,
                                                size: 1,
                                              ),
                                              onSelected: (String value) {
                                                addToCartCheckout(index, value);
                                              },
                                              itemBuilder:
                                                  (BuildContext context) {
                                                return items
                                                    .map<PopupMenuItem<String>>(
                                                        (String value) {
                                                  return new PopupMenuItem(
                                                      child: new Text(value),
                                                      value: value);
                                                }).toList();
                                              },
                                            ),
                                          ],
                                        ),
                                      ), // ),

                                      GestureDetector(
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          margin: EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.add,
                                            size: 12,
                                            color: colors.fontColor,
                                          ),
                                          decoration: BoxDecoration(
                                              color: colors.lightWhite,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(3))),
                                        ),
                                        onTap: () {
                                          addToCartCheckout(
                                              index,
                                              (int.parse(cartList[index].qty) +
                                                      1)
                                                  .toString());
                                        },
                                      )
                                    ],
                                  ),
                                ],
                              )
                            : Container(),
                      ],
                    ),
                  ),
                )
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getTranslated(context, 'SUBTOTAL'),
                  style: Theme.of(context)
                      .textTheme
                      .caption
                      .copyWith(color: colors.lightBlack2),
                ),
                Text(
                  CUR_CURRENCY + " " + price.toString(),
                  style: Theme.of(context)
                      .textTheme
                      .caption
                      .copyWith(color: colors.lightBlack2),
                ),
                Text(
                  CUR_CURRENCY + " " + cartList[index].perItemTotal,
                  style: Theme.of(context)
                      .textTheme
                      .caption
                      .copyWith(color: colors.lightBlack2),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getTranslated(context, 'TAXPER'),
                  style: Theme.of(context)
                      .textTheme
                      .caption
                      .copyWith(color: colors.lightBlack2),
                ),
                Text(
                  cartList[index].productList[0].tax + "%",
                  style: Theme.of(context)
                      .textTheme
                      .caption
                      .copyWith(color: colors.lightBlack2),
                ),
                Text(
                  CUR_CURRENCY + " " + taxAmt.toStringAsFixed(2),
                  style: Theme.of(context)
                      .textTheme
                      .caption
                      .copyWith(color: colors.lightBlack2),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getTranslated(context, 'TOTAL_LBL'),
                  style: Theme.of(context).textTheme.caption.copyWith(
                      fontWeight: FontWeight.bold, color: colors.lightBlack2),
                ),
                Text(
                  CUR_CURRENCY +
                      " " +
                      (double.parse(cartList[index].perItemTotal) + taxAmt)
                          .toStringAsFixed(2)
                          .toString(),
                  //+ " "+cartList[index].productList[0].taxrs,
                  style: Theme.of(context).textTheme.caption.copyWith(
                      fontWeight: FontWeight.bold, color: colors.lightBlack2),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget saveLaterItem(int index) {
    int selectedPos = 0;
    for (int i = 0;
        i < saveLaterList[index].productList[0].prVarientList.length;
        i++) {
      if (saveLaterList[index].varientId ==
          saveLaterList[index].productList[0].prVarientList[i].id)
        selectedPos = i;
    }

    double price = double.parse(saveLaterList[index]
        .productList[0]
        .prVarientList[selectedPos]
        .disPrice);
    if (price == 0)
      price = double.parse(
          saveLaterList[index].productList[0].prVarientList[selectedPos].price);

    saveLaterList[index].perItemPrice = price.toString();
    saveLaterList[index].perItemTotal =
        (price * double.parse(saveLaterList[index].qty)).toString();

    return Card(
      elevation: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: <Widget>[
            Hero(
                tag: "$index${saveLaterList[index].productList[0].id}",
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(7.0),
                    child: FadeInImage(
                      image: NetworkImage(
                          saveLaterList[index].productList[0].image),
                      height: 80.0,
                      width: 80.0,
                      fit: extendImg ? BoxFit.fill : BoxFit.contain,
                      placeholder: placeHolder(80),
                    ))),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(top: 5.0),
                            child: Text(
                              saveLaterList[index].productList[0].name,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle2
                                  .copyWith(color: colors.lightBlack),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                start: 8.0, end: 8, bottom: 8),
                            child: Icon(
                              Icons.close,
                              size: 15,
                              color: colors.fontColor,
                            ),
                          ),
                          onTap: () {
                            if (_isProgress == false)
                              removeFromCart(index, true, saveLaterList, true);
                          },
                        )
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          double.parse(saveLaterList[index]
                                      .productList[0]
                                      .prVarientList[selectedPos]
                                      .disPrice) !=
                                  0
                              ? CUR_CURRENCY +
                                  "" +
                                  saveLaterList[index]
                                      .productList[0]
                                      .prVarientList[selectedPos]
                                      .price
                              : "",
                          style: Theme.of(context).textTheme.overline.copyWith(
                              decoration: TextDecoration.lineThrough,
                              letterSpacing: 0.7),
                        ),
                        Text(
                          " " + CUR_CURRENCY + " " + price.toString(),
                          style: TextStyle(
                              color: colors.fontColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    saveLaterList[index].productList[0].availability == "1" ||
                            saveLaterList[index].productList[0].stockType ==
                                "null"
                        ? Row(
                            children: <Widget>[
                              GestureDetector(
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: colors.lightWhite,
                                      borderRadius: new BorderRadius.all(
                                          const Radius.circular(4.0))),
                                  child: Text(
                                    getTranslated(context, 'MOVE_TO_CART'),
                                    style: TextStyle(
                                        color: colors.fontColor, fontSize: 11),
                                  ),
                                ),
                                onTap: () {
                                  saveForLater(
                                      saveLaterList[index].varientId,
                                      "0",
                                      saveLaterList[index].qty,
                                      double.parse(
                                          saveLaterList[index].perItemTotal),
                                      saveLaterList[index]);
                                },
                              ),
                            ],
                          )
                        : Container(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  updateCart() {
    if (mounted) setState(() {});
  }

  Future<void> _getCart(String save) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {USER_ID: CUR_USERID, SAVE_LATER: save};
        Response response =
            await post(getCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          if (ISFLAT_DEL) delCharge = double.parse(getdata[DEL_CHARGE]);

          oriPrice = double.parse(getdata[SUB_TOTAL]);
          taxAmt = double.parse(getdata[TAX_AMT]);
          taxPer = double.parse(getdata[TAX_PER]);
          totalPrice = delCharge + oriPrice + taxAmt;
          cartList = (data as List)
              .map((data) => new Section_Model.fromCart(data))
              .toList();

          for (int i = 0; i < cartList.length; i++)
            _controller.add(new TextEditingController());
        } else {
          if (msg != 'Cart Is Empty !') setSnackbar(msg, _scaffoldKey);
        }
        if (mounted)
          setState(() {
            _isCartLoad = false;
          });
        if (mounted) setState(() {});
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'), _scaffoldKey);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  Future<Null> _getSaveLater(String save) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {USER_ID: CUR_USERID, SAVE_LATER: save};
        Response response =
            await post(getCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          saveLaterList = (data as List)
              .map((data) => new Section_Model.fromCart(data))
              .toList();

          for (int i = 0; i < cartList.length; i++)
            _controller.add(new TextEditingController());
        } else {
          if (msg != 'Cart Is Empty !') setSnackbar(msg, _scaffoldKey);
        }
        if (mounted)
          setState(() {
            _isSaveLoad = false;
          });
        if (mounted) setState(() {});
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'), _scaffoldKey);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }

    return null;
  }

  Future<void> addToCart(int index, String qty) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted)
          setState(() {
            _isProgress = true;
          });

        var parameter = {
          PRODUCT_VARIENT_ID: cartList[index].varientId,
          USER_ID: CUR_USERID,
          QTY: qty,
        };

        Response response =
            await post(manageCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          String qty = data['total_quantity'];
          CUR_CART_COUNT = data['cart_count'];

          cartList[index].qty = qty;

          oriPrice = double.parse(data['sub_total']);
          _controller[index].text = qty;
          totalPrice = 0;
          taxAmt = double.parse(data[TAX_AMT]);
          totalPrice = oriPrice + taxAmt;
        } else {
          setSnackbar(msg, _scaffoldKey);
        }

        if (mounted)
          setState(() {
            _isProgress = false;
          });

        widget.updateHome();
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'), _scaffoldKey);
        if (mounted)
          setState(() {
            _isProgress = false;
          });
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  Future<void> addToCartCheckout(int index, String qty) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted)
          checkoutState(() {
            _isProgress = true;
          });

        var parameter = {
          PRODUCT_VARIENT_ID: cartList[index].varientId,
          USER_ID: CUR_USERID,
          QTY: qty,
        };

        Response response =
            await post(manageCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            String qty = data['total_quantity'];
            CUR_CART_COUNT = data['cart_count'];

            cartList[index].qty = qty;
            taxAmt = double.parse(data[TAX_AMT]);
            oriPrice = double.parse(data['sub_total']);
            _controller[index].text = qty;
            totalPrice = 0;

            if (!ISFLAT_DEL) {
              if ((oriPrice + taxAmt) <
                  double.parse(addressList[selectedAddress].freeAmt))
                delCharge =
                    double.parse(addressList[selectedAddress].deliveryCharge);
              else
                delCharge = 0;
            }
            totalPrice = delCharge + oriPrice + taxAmt;

            if (isPromoValid) {
              validatePromo();
            } else if (isUseWallet) {
              if (mounted)
                checkoutState(() {
                  remWalBal = 0;
                  payMethod = null;
                  usedBal = 0;
                  isUseWallet = false;
                  isPayLayShow = true;
                  _isProgress = false;
                });
            } else {
              if (mounted)
                checkoutState(() {
                  _isProgress = false;
                });
            }
          } else {
            setSnackbar(msg, _checkscaffoldKey);
            if (mounted)
              checkoutState(() {
                _isProgress = false;
              });
          }

          widget.updateHome();
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'), _checkscaffoldKey);
        if (mounted)
          checkoutState(() {
            _isProgress = false;
          });
      }
    } else {
      if (mounted)
        checkoutState(() {
          _isNetworkAvail = false;
        });
    }
  }

  saveForLater(String id, String save, String qty, double price,
      Section_Model curItem) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted)
          setState(() {
            _isProgress = true;
          });

        var parameter = {
          PRODUCT_VARIENT_ID: id,
          USER_ID: CUR_USERID,
          QTY: qty,
          SAVE_LATER: save
        };

        Response response =
            await post(manageCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          String qty = data['total_quantity'];
          CUR_CART_COUNT = data['cart_count'];

          if (save == "1") {
            saveLaterList.add(curItem);
            cartList.removeWhere((item) => item.varientId == id);
            oriPrice = oriPrice - price;

            totalPrice = 0;
            totalPrice = oriPrice + taxAmt;
          } else {
            cartList.add(curItem);
            saveLaterList.removeWhere((item) => item.varientId == id);
            oriPrice = oriPrice + price;

            totalPrice = 0;
            totalPrice = oriPrice + taxAmt;
          }
        } else {
          setSnackbar(msg, _scaffoldKey);
        }
        if (mounted)
          setState(() {
            _isProgress = false;
          });
        if (widget.updateHome != null) widget.updateHome();
        if (widget.updateParent != null) widget.updateParent();
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'), _scaffoldKey);
        if (mounted)
          setState(() {
            _isProgress = false;
          });
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  removeFromCartCheckout(int index, bool remove) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted)
          checkoutState(() {
            _isProgress = true;
          });

        var parameter = {
          PRODUCT_VARIENT_ID: cartList[index].varientId,
          USER_ID: CUR_USERID,
          QTY: remove ? "0" : (int.parse(cartList[index].qty) - 1).toString()
        };

        Response response =
            await post(manageCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            String qty = data['total_quantity'];
            CUR_CART_COUNT = data['cart_count'];
            if (qty == "0") remove = true;

            if (remove) {
              oriPrice = oriPrice - double.parse(cartList[index].perItemTotal);

              cartList.removeWhere(
                  (item) => item.varientId == cartList[index].varientId);
            } else {
              oriPrice = oriPrice - double.parse(cartList[index].perItemPrice);
              cartList[index].qty = qty.toString();
            }
            taxAmt = double.parse(data[TAX_AMT]);
            if (!ISFLAT_DEL) {
              if ((oriPrice + taxAmt) <
                  double.parse(addressList[selectedAddress].freeAmt))
                delCharge =
                    double.parse(addressList[selectedAddress].deliveryCharge);
              else
                delCharge = 0;
            }

            totalPrice = 0;

            totalPrice = delCharge + oriPrice + taxAmt;

            if (isPromoValid) {
              validatePromo();
            } else if (isUseWallet) {
              if (mounted)
                setState(() {
                  remWalBal = 0;
                  payMethod = null;
                  usedBal = 0;
                  isPayLayShow = true;
                  isUseWallet = false;
                  _isProgress = false;
                });
            } else {
              if (mounted)
                checkoutState(() {
                  _isProgress = false;
                });
            }
          } else {
            setSnackbar(msg, _checkscaffoldKey);
            if (mounted)
              checkoutState(() {
                _isProgress = false;
              });
          }

          if (widget.updateHome != null) widget.updateHome();
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'), _checkscaffoldKey);
        if (mounted)
          checkoutState(() {
            _isProgress = false;
          });
      }
    } else {
      if (mounted)
        checkoutState(() {
          _isNetworkAvail = false;
        });
    }
  }

  removeFromCart(
      int index, bool remove, List<Section_Model> cartList, bool move) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted)
          setState(() {
            _isProgress = true;
          });

        var parameter = {
          PRODUCT_VARIENT_ID: cartList[index].varientId,
          USER_ID: CUR_USERID,
          QTY: remove ? "0" : (int.parse(cartList[index].qty) - 1).toString()
        };


        Response response =
            await post(manageCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          String qty = data['total_quantity'];
          CUR_CART_COUNT = data['cart_count'];
          if (move == false) {
            if (qty == "0") remove = true;

            if (remove) {
              oriPrice = oriPrice - double.parse(cartList[index].perItemTotal);

              cartList.removeWhere(
                  (item) => item.varientId == cartList[index].varientId);
            } else {
              oriPrice = oriPrice - double.parse(cartList[index].perItemPrice);
              cartList[index].qty = qty.toString();
            }
            taxAmt = double.parse(data[TAX_AMT]);
            totalPrice = 0;
            totalPrice = oriPrice + taxAmt;
          } else {
            if (qty == "0") remove = true;

            if (remove) {
              cartList.removeWhere(
                  (item) => item.varientId == cartList[index].varientId);
            }
          }
        } else {
          setSnackbar(msg, _scaffoldKey);
        }
        if (mounted)
          setState(() {
            _isProgress = false;
          });
        if (widget.updateHome != null) widget.updateHome();
        if (widget.updateParent != null) widget.updateParent();
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'), _scaffoldKey);
        if (mounted)
          setState(() {
            _isProgress = false;
          });
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  setSnackbar(String msg, GlobalKey<ScaffoldState> _scaffoldKey) {
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

  _showContent() {
    return _isCartLoad
        ? shimmer()
        : cartList.length == 0 && saveLaterList.length == 0
            ? cartEmpty()
            : Column(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: RefreshIndicator(
                            key: _refreshIndicatorKey,
                            onRefresh: _refresh,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: cartList.length,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return listItem(index);
                                    },
                                  ),
                                  saveLaterList.length > 0
                                      ? Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            getTranslated(
                                                context, 'SAVEFORLATER_BTN'),
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle1,
                                          ),
                                        )
                                      : Container(),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: saveLaterList.length,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return saveLaterItem(index);
                                    },
                                  ),
                                ],
                              ),
                            ))),
                  ),
                  Container(
                    color: colors.white,
                    child: Row(children: <Widget>[
                      Padding(
                          padding: EdgeInsetsDirectional.only(start: 15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CUR_CURRENCY + " $oriPrice",
                                style: TextStyle(
                                    color: colors.fontColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(cartList.length.toString() + " Items"),
                            ],
                          )),
                      Spacer(),
                      SimBtn(
                          size: 0.4,
                          title: getTranslated(context, 'PROCEED_CHECKOUT'),
                          onBtnSelected: () async {
                            if (oriPrice > 0) {
                              /* await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CheckOut(widget.updateHome),
                      ),
                    );*/
                              checkout();
                              if (mounted) setState(() {});
                            } else
                              setSnackbar(getTranslated(context, 'ADD_ITEM'),
                                  _scaffoldKey);
                          }),
                    ]),
                  ),
                ],
              );
  }

  cartEmpty() {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noCartImage(context),
          noCartText(context),
          noCartDec(context),
          shopNow()
        ]),
      ),
    );
  }

  noCartImage(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/empty_cart.svg',
      fit: BoxFit.contain,
    );
  }

  noCartText(BuildContext context) {
    return Container(
        child: Text(getTranslated(context, 'NO_CART'),
            style: Theme.of(context).textTheme.headline5.copyWith(
                color: colors.primary, fontWeight: FontWeight.normal)));
  }

  noCartDec(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(top: 30.0, start: 30.0, end: 30.0),
      child: Text(getTranslated(context, 'CART_DESC'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headline6.copyWith(
                color: colors.lightBlack2,
                fontWeight: FontWeight.normal,
              )),
    );
  }

  shopNow() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 28.0),
      child: CupertinoButton(
        child: Container(
            width: deviceWidth * 0.7,
            height: 45,
            alignment: FractionalOffset.center,
            decoration: new BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.grad1Color, colors.grad2Color],
                  stops: [0, 1]),
              borderRadius: new BorderRadius.all(const Radius.circular(50.0)),
            ),
            child: Text(getTranslated(context, 'SHOP_NOW'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline6.copyWith(
                    color: colors.white, fontWeight: FontWeight.normal))),
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/home', (Route<dynamic> route) => false);
        },
      ),
    );
  }

  checkout() {
    _getAddress();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            checkoutState = setState;
            return Container(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8),
                child: Scaffold(
                  key: _checkscaffoldKey,
                  // appBar: getAppBar(getTranslated(context, 'CHECKOUT'), context),
                  body: _isNetworkAvail
                      ? cartList.length == 0
                          ? cartEmpty()
                          : _isLoading
                              ? shimmer()
                              : Column(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: <Widget>[
                                          SingleChildScrollView(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  address(),
                                                  payment(),
                                                  cartItems(),
                                                  promo(),
                                                  orderSummary(),
                                                ],
                                              ),
                                            ),
                                          ),
                                          showCircularProgress(
                                              _isProgress, colors.primary),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      color: colors.white,
                                      child: Row(children: <Widget>[
                                        Padding(
                                            padding: EdgeInsetsDirectional.only(
                                                start: 15.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  CUR_CURRENCY + " $totalPrice",
                                                  style: TextStyle(
                                                      color: colors.fontColor,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                    cartList.length.toString() +
                                                        " Items"),
                                              ],
                                            )),
                                        Spacer(),
                                        SimBtn(
                                            size: 0.4,
                                            title: getTranslated(
                                                context, 'PLACE_ORDER'),
                                            onBtnSelected: () {
                                              if (selAddress == null ||
                                                  selAddress.isEmpty) {
                                                msg = getTranslated(
                                                    context, 'addressWarning');
                                                Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (BuildContext
                                                              context) =>
                                                          ManageAddress(
                                                        home: false,
                                                      ),
                                                    ));
                                              } else if (payMethod == null ||
                                                  payMethod.isEmpty) {
                                                msg = getTranslated(
                                                    context, 'payWarning');
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (BuildContext
                                                                context) =>
                                                            Payment(
                                                                updateCheckout,
                                                                msg)));
                                              } else if (isTimeSlot &&
                                                  int.parse(allowDay) > 0 &&
                                                  (selDate == null ||
                                                      selDate.isEmpty)) {
                                                msg = getTranslated(
                                                    context, 'dateWarning');
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (BuildContext
                                                                context) =>
                                                            Payment(
                                                                updateCheckout,
                                                                msg)));
                                              } else if (isTimeSlot &&
                                                  timeSlotList.length > 0 &&
                                                  (selTime == null ||
                                                      selTime.isEmpty)) {
                                                msg = getTranslated(
                                                    context, 'timeWarning');
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (BuildContext
                                                                context) =>
                                                            Payment(
                                                                updateCheckout,
                                                                msg)));
                                              } else if (payMethod ==
                                                  getTranslated(
                                                      context, 'PAYPAL_LBL'))
                                                placeOrder('');
                                              else if (payMethod ==
                                                  getTranslated(
                                                      context, 'RAZORPAY_LBL'))
                                                razorpayPayment();
                                              else if (payMethod ==
                                                  getTranslated(
                                                      context, 'PAYSTACK_LBL'))
                                                paystackPayment(context);
                                              else if (payMethod ==
                                                  getTranslated(context,
                                                      'FLUTTERWAVE_LBL'))
                                                flutterwavePayment();
                                              else if (payMethod ==
                                                  getTranslated(
                                                      context, 'STRIPE_LBL'))
                                                stripePayment();
                                              else if (payMethod ==
                                                  getTranslated(
                                                      context, 'PAYTM_LBL'))
                                                paytmPayment();
                                              else
                                                placeOrder('');
                                            }),
                                      ]),
                                    ),
                                  ],
                                )
                      : noInternet(context),
                ));
          });
        });
  }

  Future<void> _getAddress() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
        };
        Response response =
            await post(getAddressApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            addressList = (data as List)
                .map((data) => new User.fromAddress(data))
                .toList();

            if (addressList.length == 1) {
              selectedAddress = 0;
              selAddress = addressList[0].id;
              if (!ISFLAT_DEL) {
                if (totalPrice < double.parse(addressList[0].freeAmt))
                  delCharge = double.parse(addressList[0].deliveryCharge);
                else
                  delCharge = 0;
              }
            } else {
              for (int i = 0; i < addressList.length; i++) {
                if (addressList[i].isDefault == "1") {
                  selectedAddress = i;
                  selAddress = addressList[i].id;
                  if (!ISFLAT_DEL) {
                    if (totalPrice < double.parse(addressList[i].freeAmt))
                      delCharge = double.parse(addressList[i].deliveryCharge);
                    else
                      delCharge = 0;
                  }
                }
              }
            }

            if (!ISFLAT_DEL) {
              totalPrice = totalPrice + delCharge;
            }
          } else {}
          if (mounted) {
            checkoutState(() {
              _isLoading = false;
            });
          }
        } else {
          setSnackbar(
              getTranslated(context, 'somethingMSg'), _checkscaffoldKey);
          if (mounted)
            setState(() {
              _isLoading = false;
            });
        }
      } on TimeoutException catch (_) {}
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    placeOrder(response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted)
      setState(() {
        _isProgress = false;
      });
    print("res*****${response.message}");
    // var getdata = jsonDecode(response.message);
    // print("res*****${getdata["description"]}");
    setSnackbar(response.message, _checkscaffoldKey);
    //print("res*****${getdata["description"]}");
    //AddTransaction(tranId, orderId, SUCCESS, msg,false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("EXTERNAL_WALLET: " + response.walletName);
  }

  updateCheckout() {
    if (mounted) checkoutState(() {});
  }

  razorpayPayment() async {
    String contact = await getPrefrence(MOBILE);
    String email = await getPrefrence(EMAIL);

    double amt = totalPrice * 100;

    if (contact != '' && email != '') {
      if (mounted)
        setState(() {
          _isProgress = true;
        });

      var options = {
        KEY: razorpayId,
        AMOUNT: amt.toString(),
        NAME: CUR_USERNAME,
        'prefill': {CONTACT: contact, EMAIL: email},
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint(e);
      }
    } else {
      if (email == '')
        setSnackbar(getTranslated(context, 'emailWarning'), _checkscaffoldKey);
      else if (contact == '')
        setSnackbar(getTranslated(context, 'phoneWarning'), _checkscaffoldKey);
    }
  }

  void paytmPayment() async {
    String payment_response;
    setState(() {
      _isProgress = true;
    });
    String orderId = DateTime.now().millisecondsSinceEpoch.toString();

    String callBackUrl = (payTesting
            ? 'https://securegw-stage.paytm.in'
            : 'https://securegw.paytm.in') +
        '/theia/paytmCallback?ORDER_ID=' +
        orderId;


    var parameter = {
      AMOUNT: totalPrice.toString(),
       USER_ID:CUR_USERID,
      ORDER_ID: orderId
    };

    try {
      final response = await post(
        getPytmChecsumkApi,
        body: parameter,
        headers: headers,
      );



      var getdata = json.decode(response.body);

      bool error = getdata["error"];

      if (!error) {
        String txnToken = getdata["txn_token"];

        setState(() {
          payment_response = txnToken;
        });
        // orderId, mId, txnToken, txnAmount, callback
        var paytmResponse = Paytm.payWithPaytm(paytmMerId, orderId, txnToken,
            totalPrice.toString(), callBackUrl, payTesting);

        paytmResponse.then((value) {
          print(value);
          setState(() {
            _isProgress = false;
            print("Value is ");
            print(value);
            if (value['error']) {
              payment_response = value['errorMessage'];



              if (value['response'] != null)
                AddTransaction(value['response']['TXNID'], orderId,
                    value['response']['STATUS'], payment_response, false);
            } else {
              if (value['response'] != null) {
                payment_response = value['response']['STATUS'];
                if (payment_response == "TXN_SUCCESS")
                  placeOrder(value['response']['TXNID']);
                else
                  AddTransaction(
                      value['response']['TXNID'],
                      orderId,
                      value['response']['STATUS'],
                      value['errorMessage'],
                      false);
              }
            }

            setSnackbar(payment_response, _checkscaffoldKey);
          });
        });
      } else {
        setState(() {
          _isProgress=false;
        });
        setSnackbar(getdata["message"], _checkscaffoldKey);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> placeOrder(String tranId) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      checkoutState(() {
        _isProgress = true;
      });

      String mob = await getPrefrence(MOBILE);
      String varientId, quantity;
      for (Section_Model sec in cartList) {
        varientId =
            varientId != null ? varientId + "," + sec.varientId : sec.varientId;
        quantity = quantity != null ? quantity + "," + sec.qty : sec.qty;
      }
      String payVia;
      if (payMethod == getTranslated(context, 'COD_LBL'))
        payVia = "COD";
      else if (payMethod == getTranslated(context, 'PAYPAL_LBL'))
        payVia = "PayPal";
      else if (payMethod == getTranslated(context, 'PAYUMONEY_LBL'))
        payVia = "PayUMoney";
      else if (payMethod == getTranslated(context, 'RAZORPAY_LBL'))
        payVia = "RazorPay";
      else if (payMethod == getTranslated(context, 'PAYSTACK_LBL'))
        payVia = "Paystack";
      else if (payMethod == getTranslated(context, 'FLUTTERWAVE_LBL'))
        payVia = "Flutterwave";
      else if (payMethod == getTranslated(context, 'STRIPE_LBL'))
        payVia = "Stripe";
      else if (payMethod == getTranslated(context, 'PAYTM_LBL'))
        payVia = "Paytm";
      else if (payMethod == "Wallet") payVia = "Wallet";
      try {
        var parameter = {
          USER_ID: CUR_USERID,
          MOBILE: mob,
          PRODUCT_VARIENT_ID: varientId,
          QUANTITY: quantity,
          TOTAL: oriPrice.toString(),
          DEL_CHARGE: delCharge.toString(),
          TAX_AMT: taxAmt.toString(),
          TAX_PER: taxPer.toString(),
          FINAL_TOTAL: totalPrice.toString(),
          PAYMENT_METHOD: payVia,
          ADD_ID: selAddress,
          ISWALLETBALUSED: isUseWallet ? "1" : "0",
          WALLET_BAL_USED: usedBal.toString(),
        };

        if (isTimeSlot) {
          parameter[DELIVERY_TIME] = selTime ?? 'Anytime';
          parameter[DELIVERY_DATE] = selDate ?? '';
        }
        if (isPromoValid) {
          parameter[PROMOCODE] = promocode;
          parameter[PROMO_DIS] = promoAmt.toString();
        }

        if (payMethod == getTranslated(context, 'PAYPAL_LBL')) {
          parameter[ACTIVE_STATUS] = WAITING;
        } else if (payMethod == getTranslated(context, 'STRIPE_LBL')) {
          if (tranId == "succeeded")
            parameter[ACTIVE_STATUS] = SUCCESS;
          else
            parameter[ACTIVE_STATUS] = WAITING;
        }


        Response response =
            await post(placeOrderApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata["error"];
          String msg = getdata["message"];
          if (!error) {
            String orderId = getdata["order_id"].toString();
            if (payMethod == getTranslated(context, 'RAZORPAY_LBL')) {
              AddTransaction(tranId, orderId, SUCCESS, msg, true);
            } else if (payMethod == getTranslated(context, 'PAYPAL_LBL')) {
              paypalPayment(orderId);
            } else if (payMethod == getTranslated(context, 'STRIPE_LBL')) {
              AddTransaction(stripePayId, orderId,
                  tranId == "succeeded" ? SUCCESS : WAITING, msg, true);
            } else if (payMethod == getTranslated(context, 'PAYSTACK_LBL')) {
              AddTransaction(tranId, orderId, SUCCESS, msg, true);
            } else if (payMethod == getTranslated(context, 'PAYTM_LBL')) {
              AddTransaction(tranId, orderId, SUCCESS, msg, true);
            } else {
              CUR_CART_COUNT = "0";
              promoAmt = 0;
              remWalBal = 0;
              usedBal = 0;
              payMethod = '';
              isPromoValid = false;
              isUseWallet = false;
              isPayLayShow = true;
              selectedMethod = 0;
              totalPrice = 0;
              oriPrice = 0;
              taxAmt = 0;
              taxPer = 0;
              delCharge = 0;
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => OrderSuccess()),
                  ModalRoute.withName('/home'));
            }
          } else {
            setSnackbar(msg, _checkscaffoldKey);
          }
          if (mounted)
            setState(() {
              _isProgress = false;
            });
        }
      } on TimeoutException catch (_) {
        if (mounted)
          setState(() {
            _isProgress = false;
          });
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  Future<void> paypalPayment(String orderId) async {
    try {
      var parameter = {
        USER_ID: CUR_USERID,
        ORDER_ID: orderId,
        AMOUNT: totalPrice.toString()
      };
      Response response =
          await post(paypalTransactionApi, body: parameter, headers: headers)
              .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      bool error = getdata["error"];
      String msg = getdata["message"];
      if (!error) {
        String data = getdata["data"];
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => PaypalWebview(
                      url: data,
                      from: "order",
                    )));
        checkoutState(() {
          _isProgress = false;
        });
      } else {
        checkoutState(() {
          _isProgress = false;
        });
        setSnackbar(msg, _checkscaffoldKey);
      }
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg'), _checkscaffoldKey);
    }
  }

  Future<void> AddTransaction(String tranId, String orderID, String status,
      String msg, bool redirect) async {
    try {
      var parameter = {
        USER_ID: CUR_USERID,
        ORDER_ID: orderID,
        TYPE: payMethod,
        TXNID: tranId,
        AMOUNT: totalPrice.toString(),
        STATUS: status,
        MSG: msg
      };
      Response response =
          await post(addTransactionApi, body: parameter, headers: headers)
              .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      bool error = getdata["error"];
      String msg1 = getdata["message"];
      if (!error) {
        if (redirect) {
          CUR_CART_COUNT = "0";
          promoAmt = 0;
          remWalBal = 0;
          usedBal = 0;
          payMethod = '';
          isPromoValid = false;
          isUseWallet = false;
          isPayLayShow = true;
          selectedMethod = 0;
          totalPrice = 0;
          oriPrice = 0;
          taxAmt = 0;
          taxPer = 0;
          delCharge = 0;
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => OrderSuccess()),
              ModalRoute.withName('/home'));
        }
      } else {
        setSnackbar(msg1, _checkscaffoldKey);
      }
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg'), _checkscaffoldKey);
    }
  }

  paystackPayment(BuildContext context) async {
    if (mounted)
      setState(() {
        _isProgress = true;
      });

    String email = await getPrefrence(EMAIL);

    Charge charge = Charge()
      ..amount = totalPrice.toInt()
      ..reference = _getReference()
      ..email = email;

    try {
      CheckoutResponse response = await PaystackPlugin.checkout(
        context,
        method: CheckoutMethod.card,
        charge: charge,
      );
      if (response.status) {
        placeOrder(response.reference);
      } else {
        setSnackbar(response.message, _checkscaffoldKey);
        if (mounted)
          setState(() {
            _isProgress = false;
          });
      }
    } catch (e) {
      if (mounted) setState(() => _isProgress = false);
      rethrow;
    }
  }

  String _getReference() {
    String platform;
    if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Android';
    }

    return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
  }

  stripePayment() async {
    if (mounted)
      setState(() {
        _isProgress = true;
      });

    var response = await StripeService.payWithNewCard(
        amount: (totalPrice.toInt() * 100).toString(), currency: stripeCurCode);

    if (response.message == "Transaction successful") {
      placeOrder(response.status);
    } else if (response.status == 'pending' || response.status == "captured") {
      placeOrder(response.status);
    } else {
      if (mounted)
        setState(() {
          _isProgress = false;
        });
    }
    setSnackbar(response.message, _checkscaffoldKey);
  }

  address() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on),
            addressList.length > 0
                ? Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsetsDirectional.only(bottom: 5.0),
                            child: Text(addressList[selectedAddress].name),
                          ),
                          Text(
                            addressList[selectedAddress].address +
                                ", " +
                                addressList[selectedAddress].area +
                                ", " +
                                addressList[selectedAddress].city +
                                ", " +
                                addressList[selectedAddress].state +
                                ", " +
                                addressList[selectedAddress].country +
                                ", " +
                                addressList[selectedAddress].pincode,
                            style: Theme.of(context)
                                .textTheme
                                .caption
                                .copyWith(color: colors.lightBlack),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: Row(
                              children: [
                                Text(
                                  addressList[selectedAddress].mobile,
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption
                                      .copyWith(color: colors.lightBlack),
                                ),
                                Spacer(),
                                InkWell(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: colors.lightWhite,
                                        borderRadius: new BorderRadius.all(
                                            const Radius.circular(4.0))),
                                    child: Text(
                                      getTranslated(context, 'CHANGE'),
                                      style: TextStyle(
                                          color: colors.fontColor,
                                          fontSize: 10),
                                    ),
                                  ),
                                  onTap: () async {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                ManageAddress(
                                                  home: false,
                                                )));

                                    checkoutState(() {});
                                  },
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
                      child: GestureDetector(
                        child: Text(
                          getTranslated(context, 'ADDADDRESS'),
                          style: TextStyle(
                              color: colors.fontColor,
                              fontWeight: FontWeight.bold),
                        ),
                        onTap: () async {
                          _scaffoldKey.currentState.removeCurrentSnackBar();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddAddress(
                                      update: false,
                                      index: addressList.length,
                                    )),
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  )
          ],
        ),
      ),
    );
  }

  payment() {
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () async {
          _scaffoldKey.currentState.removeCurrentSnackBar();
          msg = '';
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) =>
                      Payment(updateCheckout, msg)));
          if (mounted) checkoutState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(Icons.payment),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8.0),
                child: Text(
                  //SELECT_PAYMENT,
                  payMethod != null && payMethod != ''
                      ? payMethod
                      : getTranslated(context, 'SELECT_PAYMENT'),
                  style: TextStyle(
                      color: colors.fontColor, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  cartItems() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: cartList.length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return cartItem(index);
      },
    );
  }

  orderSummary() {
    return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, 'ORDER_SUMMARY') +
                    " (" +
                    cartList.length.toString() +
                    " items)",
                style: Theme.of(context).textTheme.subtitle2.copyWith(
                    color: colors.lightBlack, fontWeight: FontWeight.bold),
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'SUBTOTAL'),
                    style: Theme.of(context)
                        .textTheme
                        .caption
                        .copyWith(color: colors.lightBlack2),
                  ),
                  Text(
                    CUR_CURRENCY + " " + oriPrice.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .caption
                        .copyWith(color: colors.lightBlack2),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'TAXPER'),
                    style: Theme.of(context)
                        .textTheme
                        .caption
                        .copyWith(color: colors.lightBlack2),
                  ),
                  Text(
                    CUR_CURRENCY + " " + taxAmt.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .caption
                        .copyWith(color: colors.lightBlack2),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'DELIVERY_CHARGE'),
                    style: Theme.of(context)
                        .textTheme
                        .caption
                        .copyWith(color: colors.lightBlack2),
                  ),
                  Text(
                    CUR_CURRENCY + " " + delCharge.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .caption
                        .copyWith(color: colors.lightBlack2),
                  )
                ],
              ),
              isPromoValid
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, 'PROMO_CODE_DIS_LBL'),
                          style: Theme.of(context)
                              .textTheme
                              .caption
                              .copyWith(color: colors.lightBlack2),
                        ),
                        Text(
                          CUR_CURRENCY + " " + promoAmt.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .caption
                              .copyWith(color: colors.lightBlack2),
                        )
                      ],
                    )
                  : Container(),
              isUseWallet
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, 'WALLET_BAL'),
                          style: Theme.of(context).textTheme.caption,
                        ),
                        Text(
                          CUR_CURRENCY + " " + usedBal.toString(),
                          style: Theme.of(context).textTheme.caption,
                        )
                      ],
                    )
                  : Container(),
            ],
          ),
        ));
  }

  promo() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  getTranslated(context, 'PROMOCODE_LBL'),
                  style: Theme.of(context)
                      .textTheme
                      .caption
                      .copyWith(color: colors.lightBlack2),
                ),
                Spacer(),
                InkWell(
                  child: Icon(
                    Icons.refresh,
                    size: 15,
                  ),
                  onTap: () {
                    if (promoAmt != 0 && isPromoValid) {
                      if (mounted)
                        checkoutState(() {
                          totalPrice = totalPrice + promoAmt;
                          promoC.text = '';
                          isPromoValid = false;
                          promoAmt = 0;
                          promocode = '';
                        });
                    }
                  },
                )
              ],
            ),
            Container(
              //  color: red,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: promoC,
                      style: Theme.of(context).textTheme.subtitle2,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.all(
                          5,
                        ),
                        hintText: 'Promo Code..',
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colors.fontColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colors.fontColor),
                        ),
                      ),
                    ),
                  ),
                  CupertinoButton(
                    child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        alignment: FractionalOffset.center,
                        decoration: BoxDecoration(
                            color: colors.lightWhite,
                            borderRadius: new BorderRadius.all(
                                const Radius.circular(4.0))),
                        child: Text(getTranslated(context, 'APPLY'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.button.copyWith(
                                  color: colors.fontColor,
                                ))),
                    onPressed: () {
                      if (promoC.text.trim().isEmpty)
                        setSnackbar(getTranslated(context, 'ADD_PROMO'),
                            _checkscaffoldKey);
                      else if (!isPromoValid) validatePromo();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> validatePromo() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted)
          checkoutState(() {
            _isProgress = true;
          });

        var parameter = {
          USER_ID: CUR_USERID,
          PROMOCODE: promoC.text,
          FINAL_TOTAL: totalPrice.toString()
        };
        Response response =
            await post(validatePromoApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));


        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String msg = getdata["message"];
          if (!error) {
            var data = getdata["data"][0];

            totalPrice = double.parse(data["final_total"]);
            promoAmt = double.parse(data["final_discount"]);
            promocode = data["promo_code"];
            isPromoValid = true;
            setSnackbar(
                getTranslated(context, 'PROMO_SUCCESS'), _checkscaffoldKey);
          } else {
            isPromoValid = false;
            setSnackbar(msg, _checkscaffoldKey);
          }
          if (isUseWallet) {
            if (mounted)
              checkoutState(() {
                remWalBal = 0;
                payMethod = null;
                usedBal = 0;
                isUseWallet = false;
                isPayLayShow = true;
                _isProgress = false;
              });
          } else {
            checkoutState(() {
              _isProgress = false;
            });
          }
        }
      } on TimeoutException catch (_) {
        checkoutState(() {
          _isProgress = false;
        });
        setSnackbar(getTranslated(context, 'somethingMSg'), _checkscaffoldKey);
      }
    } else {
      if (mounted)
        checkoutState(() {
          _isNetworkAvail = false;
        });
    }
  }

  Future<void> flutterwavePayment() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted)
          checkoutState(() {
            _isProgress = true;
          });

        var parameter = {
          AMOUNT: totalPrice.toString(),
          USER_ID: CUR_USERID,
        };
        Response response =
            await post(flutterwaveApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        print("response****${response.body.toString()}");
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String msg = getdata["message"];
          if (!error) {
            var data = getdata["link"];
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => PaypalWebview(
                          url: data,
                          from: "order",
                        )));
          } else {
            setSnackbar(msg, _checkscaffoldKey);
          }
          checkoutState(() {
            _isProgress = false;
          });
        }
      } on TimeoutException catch (_) {
        checkoutState(() {
          _isProgress = false;
        });
        setSnackbar(getTranslated(context, 'somethingMSg'), _checkscaffoldKey);
      }
    } else {
      if (mounted)
        checkoutState(() {
          _isNetworkAvail = false;
        });
    }
  }
}
