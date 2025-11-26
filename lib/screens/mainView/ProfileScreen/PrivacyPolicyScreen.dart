import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../providers/translate_provider.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  String htmlData = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchPrivacy();
  }

  Future<void> fetchPrivacy() async {
    final response =
    await http.get(Uri.parse("https://qadampayk.com/api/privacy-policy"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      var unescape = HtmlUnescape();
      setState(() {
        htmlData = unescape.convert(data["data"]["content"] ?? "");
        loading = false;
      });
    } else {
      setState(() {
        htmlData = "<p>Failed to load Privacy Policy</p>";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.watch<TranslateProvider>().t('privacy_policy'))),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(child: Html(data: htmlData)),
    );
  }
}
