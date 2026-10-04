import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'appointments_screen.dart';
import 'messages_screen.dart';
import 'health_profile_screen.dart';
import 'settings_screen.dart';
import 'reminders_screen.dart';
import 'articles_screen.dart';


class ChatbotScreen extends StatefulWidget {

  const ChatbotScreen({super.key});


  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();

}




class _ChatbotScreenState extends State<ChatbotScreen> {


  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController = ScrollController();

  static const Map<String, String> _welcomeMessage = {
    "sender": "ai",
    "message":
        "Hi 🌸 I am Her Health Assistant.\n\n"
        "I am here to support your wellness journey. "
        "How can I help you today?"
  };

  List<Map<String, String>> messages = [_welcomeMessage];

  bool _isLoadingHistory = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Loads whatever conversation the patient already has saved. If they
  /// have no history yet (a brand-new chat), the hardcoded welcome
  /// message stays as the only thing shown -- no error, no empty screen.
  Future<void> _loadHistory() async {
    try {
      final history = await AuthService.getChatHistory();

      if (!mounted) return;

      if (history.isNotEmpty) {
        setState(() {
          messages = history
              .map((m) => {
                    "sender": (m["sender"] as String?) ?? "ai",
                    "message": (m["message"] as String?) ?? "",
                  })
              .toList();
        });
      }
    } catch (e) {
      // A failed history load isn't worth blocking the screen over --
      // the welcome message is still there, and the person can still
      // chat. Fail quietly here.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty || _isSending) {
      return;
    }

    messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      final saved = await AuthService.sendChatMessage(text);

      if (!mounted) return;

      setState(() {
        for (final m in saved) {
          messages.add({
            "sender": (m["sender"] as String?) ?? "ai",
            "message": (m["message"] as String?) ?? "",
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade400),
      );
      // Give the message back so it isn't lost on failure.
      messageController.text = text;
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
      _scrollToBottom();
    }
  }







  @override
  Widget build(BuildContext context){


    return Scaffold(



      drawer: buildDrawer(),




      appBar: AppBar(


        backgroundColor:
        const Color(0xFFE89CB0),



        title: const Text(

          "Her Health AI 🌸",

          style: TextStyle(

            color:Colors.white,

            fontWeight:
            FontWeight.bold,

          ),

        ),



        iconTheme:
        const IconThemeData(

          color:Colors.white,

        ),



        actions:[


          Padding(

            padding:
            const EdgeInsets.only(right:15),


            child:Image.asset(

              'assets/images/logo/logo.png',

              height:35,

            ),

          )


        ],


      ),







      body:Stack(



        children:[



          // Background

          Image.asset(

            'assets/images/backgrounds/background.jpeg',

            fit:BoxFit.cover,

            width:
            double.infinity,

            height:
            double.infinity,

          ),





          // Overlay

          Container(

            color:
            Colors.white.withOpacity(0.30),

          ),






          Column(


            children:[





              Expanded(


                child:ListView.builder(



                  controller: scrollController,



                  padding:
                  const EdgeInsets.all(15),



                  itemCount:
                  messages.length,



                  itemBuilder:(context,index){



                    bool isUser =
                    messages[index]["sender"]=="user";





                    return Align(



                      alignment:

                      isUser

                          ? Alignment.centerRight

                          : Alignment.centerLeft,





                      child:Container(



                        margin:
                        const EdgeInsets.symmetric(
                          vertical:8,
                        ),




                        padding:
                        const EdgeInsets.all(15),





                        constraints:
                        const BoxConstraints(

                          maxWidth:300,

                        ),





                        decoration:
                        BoxDecoration(



                          color:

                          isUser

                              ? const Color(0xFFE89CB0)

                              : const Color(0xFF959B7D),





                          borderRadius:
                          BorderRadius.circular(20),



                        ),





                        child:Text(



                          messages[index]["message"]!,



                          style:
                          const TextStyle(



                            color:
                            Colors.white,



                            fontSize:16,



                          ),


                        ),



                      ),



                    );



                  },


                ),



              ),







              // Modern AI textbox

              Align(


                alignment:
                Alignment.bottomCenter,



                child:Container(


                  margin:
                  const EdgeInsets.only(

                    left:20,

                    right:20,

                    bottom:25,

                  ),




                  padding:
                  const EdgeInsets.symmetric(

                    horizontal:18,

                    vertical:8,

                  ),





                  decoration:
                  BoxDecoration(



                    color:
                    Colors.white.withOpacity(0.92),




                    borderRadius:
                    BorderRadius.circular(35),





                    boxShadow:[


                      BoxShadow(

                        color:
                        Colors.black12,

                        blurRadius:20,

                        offset:
                        const Offset(0,8),

                      )


                    ],



                  ),







                  child:Row(



                    children:[




                      const Icon(

                        Icons.auto_awesome,

                        color:
                        Color(0xFF959B7D),

                      ),





                      const SizedBox(width:10),





                      Expanded(



                        child:TextField(



                          controller:
                          messageController,



                          decoration:
                          const InputDecoration(



                            hintText:
                            "Ask Her Health anything 🌸",




                            border:
                            InputBorder.none,



                          ),



                        ),



                      ),






                      GestureDetector(



                        onTap:
                        _isSending ? null : sendMessage,




                        child:Container(



                          height:45,

                          width:45,




                          decoration:
                          const BoxDecoration(



                            color:
                            Color(0xFFE89CB0),




                            shape:
                            BoxShape.circle,



                          ),




                          child: _isSending
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(



                            Icons.send,

                            color:
                            Colors.white,

                          ),



                        ),



                      )




                    ],



                  ),



                ),



              )





            ],



          )



        ],



      ),



    );


  }









  Drawer buildDrawer(){



    return Drawer(



      child:ListView(



        children:[





          DrawerHeader(



            decoration:
            const BoxDecoration(



              color:
              Color(0xFFE89CB0),



            ),




            child:Column(



              mainAxisAlignment:
              MainAxisAlignment.center,




              children:[



                Image.asset(



                  'assets/images/logo/logo.png',



                  height:70,



                ),





                const SizedBox(height:10),






                const Text(



                  "Her Health",



                  style:
                  TextStyle(



                    color:
                    Colors.white,



                    fontSize:24,



                    fontWeight:
                    FontWeight.bold,



                  ),



                )



              ],



            ),




          ),






          drawerItem(
            Icons.chat,
            "AI Assistant",
          ),





          ListTile(
            leading: const Icon(
              Icons.calendar_month,
              color: Color(0xFF959B7D),
            ),
            title: const Text("Appointments"),
            onTap: () {
              Navigator.pop(context); // close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppointmentsScreen(),
                ),
              );
            },
          ),





          ListTile(
            leading: const Icon(
              Icons.medical_services,
              color: Color(0xFF959B7D),
            ),
            title: const Text("Contact Doctor"),
            onTap: () {
              Navigator.pop(context); // close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MessagesScreen(),
                ),
              );
            },
          ),





          ListTile(
            leading: const Icon(
              Icons.favorite,
              color: Color(0xFF959B7D),
            ),
            title: const Text("Health Profile"),
            onTap: () {
              Navigator.pop(context); // close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HealthProfileScreen(),
                ),
              );
            },
          ),





          ListTile(
            leading: const Icon(
              Icons.notifications,
              color: Color(0xFF959B7D),
            ),
            title: const Text("Reminders"),
            onTap: () {
              Navigator.pop(context); // close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RemindersScreen(),
                ),
              );
            },
          ),





          ListTile(
            leading: const Icon(
              Icons.article,
              color: Color(0xFF959B7D),
            ),
            title: const Text("Health Articles"),
            onTap: () {
              Navigator.pop(context); // close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ArticlesScreen(),
                ),
              );
            },
          ),





          ListTile(
            leading: const Icon(
              Icons.settings,
              color: Color(0xFF959B7D),
            ),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context); // close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),




        ],



      ),



    );


  }







  Widget drawerItem(
      IconData icon,
      String title
      ){



    return ListTile(



      leading:
      Icon(

        icon,

        color:
        const Color(0xFF959B7D),

      ),





      title:
      Text(title),





      onTap:(){},



    );


  }





}
