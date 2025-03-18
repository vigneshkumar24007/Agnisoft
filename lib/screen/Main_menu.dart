import 'package:marquee/marquee.dart';
import 'package:agni_chit_saving/constants/colors.dart';
import 'package:agni_chit_saving/modal/MdlNewScheme.dart';
import 'package:agni_chit_saving/modal/MdlRateFecthing.dart';
import 'package:agni_chit_saving/routes/app_export.dart';
import 'package:agni_chit_saving/screen/kyc_screen.dart';
import 'package:agni_chit_saving/utils/commonUtils.dart';
import 'package:agni_chit_saving/widget/CommonDrawer.dart';
import 'package:agni_chit_saving/widget/CommonShimmer.dart';
import 'package:agni_chit_saving/widget/CommonTextSize.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

class Main_menu extends StatefulWidget {
  const Main_menu({Key? key});

  @override
  State<Main_menu> createState() => _Main_menuState();
}

class _Main_menuState extends State<Main_menu> {
  MdlNewScheme? selectedScheme;
  Map<String, MdlNewScheme> selectedSchemes =
      {}; // Store selected scheme per schemeId
  String Companyname = '';
  List<String> imageUrls = [
    'https://www.bneedsbill.com/flutterimg/agnisoftimg/image1.jpg',
    'https://www.bneedsbill.com/flutterimg/agnisoftimg/image2.jpg',
  ];
  @override
  void initState() {
    super.initState();
    MdlNewScheme.FutureNewScheme = _fetchNewSchemeData();
    refreshAlbums();
  }

  String _formatDate(String date) {
    try {
      DateTime parsedDate =
          DateTime.parse(date); // Parse the string to DateTime
      return DateFormat("dd-MM-yyyy")
          .format(parsedDate); // Format as DD-MM-YYYY
    } catch (e) {
      return date; // If parsing fails, return original string
    }
  }

  Future<List<MdlNewScheme>> _fetchNewSchemeData() async {
    try {
      return MdlNewScheme.fecthdatafromNewScheme();
    } catch (e) {
      print('Error fetching item data: $e');
      return [];
    }
  }

  Future<void> refreshAlbums() async {
    try {
      List<MdlRateMaster> result = await MdlRateMaster.fecthdatafromrate();
      setState(() {
        MdlRateMaster.Ratemaster = result;

        MdlRateMaster.date = MdlRateMaster.Ratemaster.isNotEmpty
            ? MdlRateMaster.Ratemaster[0].DATE
            : '';
        MdlRateMaster.GoldRate = MdlRateMaster.Ratemaster.isNotEmpty
            ? MdlRateMaster.Ratemaster[0].GOLD
            : "0.00";
        MdlRateMaster.SilverRate = MdlRateMaster.Ratemaster.isNotEmpty
            ? MdlRateMaster.Ratemaster[0].SILVER
            : "0.00";
        SharedPreferencesHelper.saveString('GOLD', MdlRateMaster.GoldRate!);
        SharedPreferencesHelper.saveString('SILVER', MdlRateMaster.SilverRate!);
        SharedPreferencesHelper.saveString('TodayRate', MdlRateMaster.date!);
        Companyname = SharedPreferencesHelper.getString('company_name') ?? '';
        /*print(date);*/
        MdlNewScheme.FutureNewScheme = MdlNewScheme.fecthdatafromNewScheme();
      });
    } catch (e) {
      commonUtils.log.i("Error In main Menu Refresh Album ${e}");
    }
  }

  Future<MdlNewScheme?> AddCatogorybottom_sheet(
      BuildContext context, String schemeId) async {
    // Fetch all scheme data
    List<MdlNewScheme> amountSchemes =
        await MdlNewScheme.fecthdatafromNewScheme();

    // Filter data based on schemeId
    List<MdlNewScheme> filteredSchemes =
        amountSchemes.where((scheme) => scheme.schemeId == schemeId).toList();

    return showModalBottomSheet<MdlNewScheme>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Allows full-screen height control
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text(
                  "Select Scheme",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: filteredSchemes.isEmpty
                      ? Center(child: Text("No schemes available for this ID"))
                      : ListView.builder(
                          itemCount: filteredSchemes.length,
                          itemBuilder: (context, index) {
                            MdlNewScheme scheme = filteredSchemes[index];

                            return Card(
                              elevation: 3,
                              child: ListTile(
                                title: Text(
                                  '₹${scheme.schemeAmount}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                      color: Color(0XFF953130)),
                                ),
                                subtitle: Text("No.of Ins: ${scheme.noIns}"),
                                trailing: Text("Type: ${scheme.schemeType}"),
                                onTap: () {
                                  Navigator.pop(context,
                                      scheme); // Return selected scheme
                                  commonUtils.log.i(
                                      'Selected Scheme: ${jsonEncode(scheme.toJson())}');
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onJoinPressed(MdlNewScheme album) async {
    MdlNewScheme schemeToUse = selectedSchemes[album.schemeId] ??
        album; // Corrected: Using selected scheme

    await storeData(schemeToUse); // Store selected scheme

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => kyc_screen(
          schemeType: schemeToUse.schemeType,
          amount: schemeToUse.schemeAmount,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Future<void> storeData(MdlNewScheme scheme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Convert scheme to JSON and save
    String schemeJson = jsonEncode(scheme.toJson());
    await prefs.setString("MdlNewScheme", schemeJson);

    commonUtils.log.i("✅ Saved Scheme: $schemeJson");
  }

  Future<MdlNewScheme?> getStoredScheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? schemeJson = prefs.getString("MdlNewScheme");

    if (schemeJson != null) {
      return MdlNewScheme.fromJson(jsonDecode(schemeJson));
    }
    return null;
  }

/*  Future<void> _onJoinPressed(MdlNewScheme album) async {
    MdlNewScheme schemeToUse = selectedScheme ?? album;
    await storeData(album);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => kyc_screen(
            schemeType: schemeToUse.schemeType,
            amount: schemeToUse.schemeAmount),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }*/

  // Future<void> _onJoinPressed(MdlNewScheme album) async {
  //   await storeData(album);
  //   Navigator.push(
  //     context,
  //     PageRouteBuilder(
  //       pageBuilder: (context, animation, secondaryAnimation) => kyc_screen(),
  //       transitionsBuilder: (context, animation, secondaryAnimation, child) {
  //         return FadeTransition(
  //           opacity: animation,
  //           child: child,
  //         );
  //       },
  //     ),
  //   );
  // }

/*  Future<void> storeData(MdlNewScheme album) async {
    SharedPreferencesHelper.removeKey("MdlMysavingsScheme");
    String albumJson = jsonEncode(album.toJson());
    SharedPreferencesHelper.saveString("MdlNewScheme", albumJson);
    commonUtils.log.i('Saved album JSON: $albumJson');
  }*/

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: AppBar(
          title: Row(
            children: [
              Image.network(
                'https://www.bneedsbill.com/flutterimg/agnisoftimg/Companylogo.png',
                height: 40,
              ),
              Text(
                Companyname,
                style: TextStyle(
                  color: Color(0XFF953130),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
      key: _scaffoldKey,
      drawer: commonDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshAlbums,
          child: Column(
            children: [
              Container(
                height: 60,
                color: Color(0XFF953130), // Background color
                child: Marquee(
                  text:
                      "GOLD RATE: ₹ ${MdlRateMaster.GoldRate}  |   SILVER RATE: ₹ ${MdlRateMaster.SilverRate} | RATE UPDATED ON : ${_formatDate(MdlRateMaster.date)},",
                  style: TextStyle(
                    color: Colors.yellow, // Text color
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  scrollAxis: Axis.horizontal,
                  blankSpace: 50.0,
                  velocity: 30.0,
                  pauseAfterRound: Duration(seconds: 1),
                  startPadding: 10,
                  accelerationDuration: Duration(seconds: 1),
                  decelerationDuration: Duration(seconds: 2),
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  CarouselSlider(
                    items: imageUrls.map((url) {
                      return T_RoundImage(
                        fit: BoxFit.contain,
                        Imgurl: url,
                        isNetWorkingImage: true,
                      );
                    }).toList(),
                    options: CarouselOptions(
                      autoPlay: true,
                      viewportFraction: 0.7,
                      height: 150,
                      autoPlayCurve: Curves.fastOutSlowIn,
                      onPageChanged: (index, _) {
                        // Slidercontroller.updatePageIndicator(index);
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Join New Scheme',
                      style: GoogleFonts.lato(
                        color: Color(0XFF953130),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: FutureBuilder<List<MdlNewScheme>>(
                  future: MdlNewScheme.FutureNewScheme,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView.builder(
                        itemCount: 3, // Show shimmer effect for only 2 items
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.all(7.0),
                            child: ShimmerEffect(
                                height: 150, width: double.infinity),
                          );
                        },
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (snapshot.hasData) {
                      List<MdlNewScheme> allNewSchemeData = snapshot.data!;
                      List<MdlNewScheme> filteredMdlNewScheme = [];

                      Map<String, MdlNewScheme> amountSchemes = {};
                      Map<String, MdlNewScheme> weightSchemes =
                          {}; // Store schemes by schemeId

                      for (var scheme in allNewSchemeData) {
                        if (scheme.schemeType == "AMOUNT" &&
                            !amountSchemes.containsKey(scheme.schemeId)) {
                          amountSchemes[scheme.schemeId] = scheme;
                        } else if (scheme.schemeType == "WEIGHT" &&
                            !weightSchemes.containsKey(scheme.schemeId)) {
                          weightSchemes[scheme.schemeId] = scheme;
                        }
                      }

                      // Add unique schemes to filtered list
                      filteredMdlNewScheme.addAll(amountSchemes.values);
                      filteredMdlNewScheme.addAll(weightSchemes.values);

                      return ListView.builder(
                        itemCount: filteredMdlNewScheme.length,
                        itemBuilder: (context, index) {
                          MdlNewScheme album = filteredMdlNewScheme[index];
                          MdlNewScheme selectedScheme =
                              selectedSchemes[album.schemeId] ?? album;

                          return GestureDetector(
                            onTap: () async {
                              MdlNewScheme? selected =
                                  await AddCatogorybottom_sheet(
                                context,
                                album.schemeId,
                              );
                              if (selected != null) {
                                setState(() {
                                  selectedSchemes[album.schemeId] =
                                      selected; // Update only for this schemeId
                                });
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Card(
                                color: Colors.lightBlue,
                                elevation: 15,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    gradient: LinearGradient(
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                      colors: [
                                        Colors.amber.shade300,
                                        Colors.white,
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 130,
                                        child: Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                image: const DecorationImage(
                                                  image: AssetImage(
                                                      'assets/images/body1.png'),
                                                  fit: BoxFit.cover,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Image.asset(
                                                      'assets/images/savings.png'),
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        album.schemeName,
                                                        style: GoogleFonts.lato(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w900),
                                                      ),
                                                      Divider(),
                                                      GestureDetector(
                                                        onTap: () async {
                                                          MdlNewScheme?
                                                              selected =
                                                              await AddCatogorybottom_sheet(
                                                            context,
                                                            album.schemeId,
                                                          );
                                                          if (selected !=
                                                              null) {
                                                            setState(() {
                                                              selectedSchemes[album
                                                                      .schemeId] =
                                                                  selected;
                                                            });
                                                          }
                                                        },
                                                        child: Column(
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Text(
                                                                  '₹ ${selectedScheme.schemeAmount}',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .blue
                                                                          .shade900,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w900,
                                                                      fontSize:
                                                                          17),
                                                                ),
                                                                SizedBox(
                                                                    width: 10),
                                                                Icon(Icons
                                                                    .expand_circle_down),
                                                              ],
                                                            ),
                                                            Text(
                                                              'NO OF INS: ${selectedScheme.noIns}',
                                                              textAlign:
                                                                  TextAlign.end,
                                                              style: commonTextStyleSmall(
                                                                  color: AppColors
                                                                      .CommonColor),
                                                            ),
                                                            Text(
                                                              'TYPE: ${selectedScheme.schemeType}',
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                              style: commonTextStyleSmall(
                                                                  color: AppColors
                                                                      .CommonColor),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          TextButton(
                                            onPressed: () {},
                                            child: const Text('Read More'),
                                          ),
                                          Container(
                                            height: 35,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                color: Color(0XFF953130)),
                                            child: TextButton(
                                              onPressed: () {
                                                _onJoinPressed(selectedScheme);
                                              },
                                              child: const Text(
                                                'Join Now',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return const Center(child: Text('No data available.'));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class T_RoundImage extends StatelessWidget {
  const T_RoundImage({
    super.key,
    required this.Imgurl,
    this.height = 50, // Default height for medium size
    this.applyImageradius = true,
    this.border,
    this.backgroundcolor,
    this.fit = BoxFit.cover, // Use BoxFit.cover for better fitting images
    this.padding,
    this.isNetWorkingImage = false,
    this.onPressed,
    this.borderradius = 20, // Adjusted to a larger, medium-sized radius
  });

  final String Imgurl;
  final double? height;
  final bool applyImageradius;
  final BoxBorder? border;
  final Color? backgroundcolor;
  final BoxFit? fit;
  final EdgeInsetsGeometry? padding;
  final double borderradius;
  final bool isNetWorkingImage;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          border: border ??
              Border.all(color: Colors.grey.shade300), // Adds a subtle border
          color: backgroundcolor ?? Colors.white, // Default background color
          borderRadius: applyImageradius
              ? BorderRadius.circular(borderradius)
              : BorderRadius.zero,
        ),
        child: ClipRRect(
          borderRadius: applyImageradius
              ? BorderRadius.circular(borderradius)
              : BorderRadius.zero,
          child: Image(
            image: isNetWorkingImage
                ? NetworkImage(Imgurl)
                : AssetImage(Imgurl) as ImageProvider,
            fit: fit, // Fit set for better appearance
          ),
        ),
      ),
    );
  }
}

class T_RoundContainer extends StatelessWidget {
  const T_RoundContainer({
    super.key,
    this.Margin,
    this.widht,
    this.Height,
    this.radius = 16,
    this.child,
    this.backgroundcolors = Colors.white,
    this.showBorder = false,
    this.bordercolor = Colors.blue,
    this.padding,
  });

  final double? widht;
  final double? Height;
  final double radius;
  final EdgeInsets? Margin;
  final Widget? child;
  final Color backgroundcolors;
  final bool showBorder;
  final Color bordercolor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widht,
      height: Height,
      margin: Margin,
      padding: padding,
      decoration: BoxDecoration(
        border: showBorder ? Border.all(color: bordercolor) : null,
        borderRadius: BorderRadius.circular(radius),
        color: backgroundcolors,
      ),
      child: child,
    );
  }
}
