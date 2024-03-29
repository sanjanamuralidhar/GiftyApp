import 'dart:async';
import 'dart:convert';

import 'package:giftty/Helper/Session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart';

import 'Helper/AppBtn.dart';
import 'Helper/Color.dart';
import 'Helper/Constant.dart';
import 'Helper/String.dart';

class Privacy_Policy extends StatefulWidget {
  final String title;

  const Privacy_Policy({Key key, this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StatePrivacy();
  }
}

class StatePrivacy extends State<Privacy_Policy> with TickerProviderStateMixin {
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  String privacy;
  Animation buttonSqueezeanimation;
  AnimationController buttonController;
  bool _isNetworkAvail = true;

  @override
  void initState() {
    super.initState();
    getSetting();
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

  @override
  void dispose() {
    buttonController.dispose();
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
    return _isLoading
        ? Scaffold(
            key: _scaffoldKey,
            appBar: getAppBar(widget.title, context),
            body: getProgress(),
          )
        : privacy != null
            ? WebviewScaffold(

                appBar: getAppBar(widget.title, context),
                withJavascript: true,
                appCacheEnabled: true,
                scrollBar: false,
                url: new Uri.dataFromString(privacy,
                        mimeType: 'text/html', encoding: utf8)
                    .toString(),
              )
            : Scaffold(
                key: _scaffoldKey,
                appBar: getAppBar(widget.title, context),
                body: _isNetworkAvail ? Container() : noInternet(context),
              );
  }

  Future<void> getSetting() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        String type;
        if (widget.title == getTranslated(context, 'PRIVACY'))
          type = PRIVACY_POLLICY;
        else if (widget.title == getTranslated(context, 'TERM'))
          type = TERM_COND;
        else if (widget.title == getTranslated(context, 'ABOUT_LBL'))
          type = ABOUT_US;
        else if (widget.title == getTranslated(context, 'CONTACT_LBL'))
          type = CONTACT_US;

        var parameter = {TYPE: type};
        Response response =
            await post(getSettingApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata["error"];
          String msg = getdata["message"];
          if (!error) {
            privacy = getdata["data"][type].toString();
          } else {
            setSnackbar(msg);
          }
        }
         if (mounted) setState(() {
          _isLoading = false;
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'));
      }
    } else {
       if (mounted) setState(() {
        _isLoading = false;
        _isNetworkAvail = false;
      });
    }
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
}
