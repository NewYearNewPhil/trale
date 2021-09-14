import 'dart:math';

import 'package:auto_size_text_pk/auto_size_text_pk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trale/core/language.dart';


import 'package:trale/core/measurement.dart';
import 'package:trale/core/theme.dart';
import 'package:trale/core/traleNotifier.dart';
import 'package:trale/core/units.dart';
import 'package:trale/main.dart';
import 'package:trale/widget/addWeightDialog.dart';
import 'package:trale/widget/linechart.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    Widget appBar(BuildContext context, Box<Measurement> box) =>
    SliverOverlapAbsorber(
      sliver: SliverSafeArea(
        top: false,
        sliver: SliverAppBar(
          expandedHeight: 300.0,
          centerTitle: true,
          title: AutoSizeText(
            AppLocalizations.of(context)!.trale.toUpperCase(),
            style: Theme.of(context).textTheme.headline4,
            maxLines: 1,
          ),
          floating: true,
          snap: true,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const <StretchMode>[
              StretchMode.blurBackground,
            ],
            background: Container(
              padding: EdgeInsets.fromLTRB(
                TraleTheme.of(context)!.padding,
                TraleTheme.of(context)!.padding + kToolbarHeight,
                TraleTheme.of(context)!.padding,
                TraleTheme.of(context)!.padding,
              ),
              child: CustomLineChart(box: box),
            ),
          ),
          elevation: Theme.of(context).bottomAppBarTheme.elevation,
        ),
      ),
      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
    );

    TraleNotifier notifier = Provider.of<TraleNotifier>(context, listen: false);

    return Container(
      color: Theme.of(context).backgroundColor,
      child: SafeArea(
        child: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: Hive.box<Measurement>(measurementBoxName).listenable(),
            builder: (BuildContext context, Box<Measurement> box, _) =>
              NestedScrollView(
                headerSliverBuilder: (BuildContext context, bool _)  {
                  return <Widget>[appBar(context, box)];
                },
                body:
                  ListView.builder(
                    itemCount: box.values.length,
                    itemBuilder: (BuildContext context, int index) {
                      Measurement? currentMeasurement = box.getAt(index);
                      if (currentMeasurement == null)
                        return const SizedBox.shrink();
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: TraleTheme.of(context)!.padding * 2,
                        ),
                        dense: true,
                        title: Text(
                          (
                              currentMeasurement.weight * notifier.unit.scaling
                          ).toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        leading: Text(
                          DateFormat('dd/MM/yy').format(currentMeasurement.date),
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                      );
                    }
                  )
              ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              // get weight from most recent measurement
              final List<Measurement> data
                = Hive.box<Measurement>(measurementBoxName).values.toList();
              data.sort((Measurement a, Measurement b) {
                return a.compareTo(b);
              });
              showAddWeightDialog(
                context: context,
                weight: data.last.weight.toDouble(),
                date: DateTime.now(),
                box: Hive.box<Measurement>(measurementBoxName),
              );
            },
            tooltip: AppLocalizations.of(context)!.addWeight,
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.addWeight),
          ),
          drawer: Drawer(
            child: Column(
              children: <Widget>[
                DrawerHeader(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/launcher/foreground_crop.png',
                        width: MediaQuery.of(context).size.width * 0.2,

                      ),
                      SizedBox(width: TraleTheme.of(context)!.padding),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            AppLocalizations.of(context)!.trale,
                            style: Theme.of(context).textTheme.headline4,
                            maxLines: 1,
                          ),
                          AutoSizeText(
                            AppLocalizations.of(context)!.tralesub,
                            style: Theme.of(context).textTheme.headline6,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ],
                  ),
                  decoration: BoxDecoration(
                    color: TraleTheme.of(context)!.isDark
                      ? TraleTheme.of(context)!.bgShade1
                      : TraleTheme.of(context)!.bgShade3,
                  ),
                ),
                AutoSizeText(
                  AppLocalizations.of(context)!.settings.toUpperCase(),
                  style: Theme.of(context).textTheme.headline6,
                  maxLines: 1,
                ),
                ListTile(
                  dense: true,
                  title: AutoSizeText(
                    AppLocalizations.of(context)!.language,
                    style: Theme.of(context).textTheme.bodyText1,
                    maxLines: 1,
                  ),
                  trailing: DropdownButton<String>(
                    value: Provider.of<TraleNotifier>(context)
                      .language.language,
                    items: <DropdownMenuItem<String>>[
                      for (Language lang in Language.supportedLanguages)
                        DropdownMenuItem<String>(
                          value: lang.language,
                          child: Text(
                            lang.languageLong(context),
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                        )
                    ],
                    onChanged: (String? lang) async {
                      setState(() {
                        Provider.of<TraleNotifier>(
                          context, listen: false
                        ).language = lang!.toLanguage();
                      });
                    },
                  ),
                ),
                ListTile(
                  dense: true,
                  title: AutoSizeText(
                    AppLocalizations.of(context)!.unit,
                    style: Theme.of(context).textTheme.bodyText1,
                    maxLines: 1,
                  ),
                  trailing: DropdownButton<TraleUnit>(
                    value: Provider.of<TraleNotifier>(context)
                        .unit,
                    items: <DropdownMenuItem<TraleUnit>>[
                      for (TraleUnit unit in TraleUnit.values)
                        DropdownMenuItem<TraleUnit>(
                          value: unit,
                          child: Text(
                            unit.name,
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                        )
                    ],
                    onChanged: (TraleUnit? newUnit) async {
                      setState(() {
                        if (newUnit != null)
                          Provider.of<TraleNotifier>(
                              context, listen: false
                          ).unit = newUnit;
                      });
                    },
                  ),
                ),

                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: TraleTheme.of(context)!.padding,
                  ),
                  title: AutoSizeText(
                    AppLocalizations.of(context)!.darkmode,
                    style: Theme.of(context).textTheme.bodyText1,
                    maxLines: 1,
                  ),
                  trailing: ToggleButtons(
                    renderBorder: false,
                    fillColor: Colors.transparent,
                    children: <Widget>[
                      const Icon(Icons.brightness_5_outlined),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: TraleTheme.of(context)!.padding,
                        ),
                        child: const Icon(Icons.brightness_auto_outlined),
                      ),
                      const Icon(Icons.brightness_2_outlined),
                    ],
                    isSelected: List<bool>.generate(
                      orderedThemeModes.length,
                      (int index) => index == orderedThemeModes.indexOf(
                        Provider.of<TraleNotifier>(context).themeMode
                      ),
                    ),
                    onPressed: (int index) {
                      setState(() {
                        Provider.of<TraleNotifier>(
                            context, listen: false,
                        ).themeMode = orderedThemeModes[index];
                      });
                    },
                  ),
                ),

                const Spacer(),
                const Divider(),
                ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.settings,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: AutoSizeText(
                      AppLocalizations.of(context)!.moreSettings,
                      style: Theme.of(context).textTheme.bodyText1,
                      maxLines: 1,
                    ),
                ),
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.question_answer_outlined,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  title: AutoSizeText(
                    AppLocalizations.of(context)!.faq,
                    style: Theme.of(context).textTheme.bodyText1,
                    maxLines: 1,
                  ),
                ),
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.question_answer_outlined,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  title: AutoSizeText(
                    AppLocalizations.of(context)!.about,
                    style: Theme.of(context).textTheme.bodyText1,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
