import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:provider/provider.dart';

import '../../../providers/translate_provider.dart'; // <-- add this

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  String htmlData = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchTerms();
  }

  Future<void> fetchTerms() async {
    final response =
    await http.get(Uri.parse("https://qadampayk.com/api/terms-conditions"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      var unescape = HtmlUnescape();
      setState(() {
        htmlData = unescape.convert(data["data"]["content"] ?? "");
        loading = false;
      });
    } else {
      setState(() {
        htmlData = "<p>Failed to load Terms & Conditions</p>";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text(context.watch<TranslateProvider>().t('terms_conditions'))),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(child: Html(data: htmlData)),
    );
  }
}
