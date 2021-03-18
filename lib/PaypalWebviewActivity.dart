import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:giftty/Helper/Color.dart';
import 'package:giftty/Helper/String.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'Cart.dart';
import 'Helper/Constant.dart';
import 'Helper/Session.dart';
import 'Model/Section_Model.dart';
import 'Order_Success.dart';

class PaypalWebview extends StatefulWidget {
  final String url, from, msg, amt;

  const PaypalWebview({Key key, this.url, this.from, this.msg, this.amt})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StatePayPalWebview();
  }
}

class StatePayPalWebview extends State<PaypalWebview> {
  String message = "";
  bool isloading = true;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final Completer<WebViewController> _controller =
  Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: getAppBar(appName, context),
        body: Stack(
          children: <Widget>[
            WebView(
              initialUrl: widget.url,
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) {
                _controller.complete(webViewController);
              },
              javascriptChannels: <JavascriptChannel>[
                _toasterJavascriptChannel(context),
              ].toSet(),
              navigationDelegate: (NavigationRequest request) async {

                if (request.url.startsWith(PAYPAL_RESPONSE_URL) ||
                    request.url.startsWith(FLUTTERWAVE_RES_URL)) {
                  if (mounted)
                    setState(() {
                      isloading = true;
                    });

                  String responseurl = request.url;

                  if (responseurl.contains("Failed") ||
                      responseurl.contains("failed")) {
                    if (mounted)
                      setState(() {
                        isloading = false;
                        message = "Transaction Failed";
                      });
                    Timer(Duration(seconds: 1), () {
                      Navigator.pop(context);
                    });
                  } else if (responseurl.contains("Completed") ||
                      responseurl.contains("completed") ||
                      responseurl.toLowerCase().contains("success")) {
                    if (mounted)
                      setState(() {
                        if (mounted)
                          setState(() {
                            message = "Transaction Successfull";
                          });
                      });
                    List<String> testdata = responseurl.split("&");
                    for (String data in testdata) {

                      if (data.split("=")[0].toLowerCase() == "tx" ||
                          data.split("=")[0].toLowerCase() ==
                              "transaction_id") {
                        // String txid = data.split("=")[1];
                        CUR_CART_COUNT = "0";

                        if (widget.from == "order") {
                          if (request.url.startsWith(PAYPAL_RESPONSE_URL))
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        OrderSuccess()),
                                ModalRoute.withName('/home'));
                          else {
                            String txid = data.split("=")[1];

                            placeOrder(txid);
                          }
                        } else if (widget.from == "wallet") {
                          if (request.url.startsWith(FLUTTERWAVE_RES_URL)) {
                            String txid = data.split("=")[1];
                            sendRequest(txid, "flutterwave");
                          }
                          else
                            Navigator.of(context).pop();
                        }

                        break;
                      }
                    }
                  }

                  return NavigationDecision.prevent;
                }

                print('allowing navigation to $request');
                return NavigationDecision.navigate;
              },
              onPageFinished: (String url) {
                setState(() {
                  isloading = false;
                });

                // print('Page finished loading: $url');
              },
            ),
            isloading
                ? Center(
              child: new CircularProgressIndicator(),
            )
                : Container(),
            message
                .trim()
                .isEmpty
                ? Container()
                : Center(
                child: Container(
                    color: colors.primary,
                    padding: EdgeInsets.all(5),
                    margin: EdgeInsets.all(5),
                    child: Text(
                      message,
                      style: TextStyle(color: colors.white),
                    )))
          ],
        ));
  }


  Future<Null> sendRequest(String txnId, String payMethod) async {
    String orderId =
        "wallet-refill-user-$CUR_USERID-${DateTime
        .now()
        .millisecondsSinceEpoch}-${Random().nextInt(900) + 100}";
    try {
      var parameter = {
        USER_ID: CUR_USERID,
        AMOUNT: widget.amt,
        TRANS_TYPE: WALLET,
        TYPE: CREDIT,
        MSG: (widget.msg == '' || widget.msg.isEmpty)
            ? "Added through wallet"
            : widget.msg,
        TXNID: txnId,
        ORDER_ID: orderId,
        STATUS: "Success",
        PAYMENT_METHOD: payMethod.toLowerCase()
      };


      Response response =
      await post(addTransactionApi, body: parameter, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      bool error = getdata["error"];
      String msg = getdata["message"];

      if (!error) {

        CUR_BALANCE = double.parse(getdata["new_balance"]).toStringAsFixed(2);

      }
      if (mounted) setState(() {
        isloading = false;
      });
      //setSnackbar(msg);
      Navigator.of(context).pop();
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg'));

      setState(() {
        isloading = false;
      });
    }
  }


  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }

  setSnackbar(String msg) {
    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.black),
      ),
      backgroundColor: colors.white,
      elevation: 1.0,
    ));
  }

  void FinishPage(String finishmessage) {
    if (mounted)
      setState(() {
        message = finishmessage;
      });
    Timer(Duration(seconds: 1), () {
      Navigator.pop(context);
    });
  }

  Future<void> placeOrder(String tranId) async {
    setState(() {
      isloading = true;
    });

    String mob = await getPrefrence(MOBILE);
    String varientId, quantity;
    for (Section_Model sec in cartList) {
      varientId =
      varientId != null ? varientId + "," + sec.varientId : sec.varientId;
      quantity = quantity != null ? quantity + "," + sec.qty : sec.qty;
    }
    String payVia;

    payVia = "Flutterwave";

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


      Response response =
      await post(placeOrderApi, body: parameter, headers: headers)
          .timeout(Duration(seconds: timeOut));

      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          String orderId = getdata["order_id"].toString();

          AddTransaction(tranId, orderId, SUCCESS, msg, true);
        } else {
          setSnackbar(msg);
        }
        if (mounted)
          setState(() {
            isloading = false;
          });
      }
    } on TimeoutException catch (_) {
      if (mounted)
        setState(() {
          isloading = false;
        });
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
        setSnackbar(msg1);
      }
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg'));
    }
  }
}

class BlankBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  Size get preferredSize => Size(0.0, 0.0);
}
