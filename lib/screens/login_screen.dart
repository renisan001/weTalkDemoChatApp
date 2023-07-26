import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:we_talk/methods.dart';
import 'package:we_talk/screens/create_account_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailCtrl = TextEditingController();
  TextEditingController passwordCtrl = TextEditingController();
  var isLoading = false;
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  var deviceToken = '';
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeLocationAndSave();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(automaticallyImplyLeading: false),
      backgroundColor: Colors.blueGrey.shade50,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Login', style: TextStyle(fontSize: 24,)),
          const SizedBox(
            height: 20,
          ),
          TextFormField(
            controller: emailCtrl,
            decoration:   InputDecoration(hintText: 'Enter Email'
                ,border: InputBorder.none,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide.none
              ),
                focusedBorder:  OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide.none
                ),
              filled: true,
              fillColor: Colors.white

            ),
          ),
          const SizedBox(
            height: 20,
          ),
          TextFormField(
            controller: passwordCtrl,
            decoration:  InputDecoration(hintText: 'Enter Password',
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide.none
              ),
              focusedBorder:  OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide.none
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(onPressed: (){
              if(emailCtrl.text == '' && passwordCtrl.text == '')
              {
                debugPrint('one field is empty');
              }
              else
              {
                setState(() {
                  isLoading = true;
                });
                login(
                    email: emailCtrl.text,password: passwordCtrl.text).then((user) async {
                  if(user != null)
                  {
                    debugPrint('this is sign in wit cred value returned => $user');

                    await fireStore.collection('user').doc(user.uid).update({
                      'deviceToken' : deviceToken
                    }).then((value) {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ));
                    });
                    debugPrint('login success');
                    emailCtrl.text = '';
                    passwordCtrl.text = '';
                  }
                  else
                  {
                    debugPrint('login failed');
                  }
                },);
                // debugPrint('after if else in create account');
              }
            }, child: const Text('Login',style: TextStyle(fontSize: 16),)),
          ),
          const SizedBox(height: 10,),
          Row(
            children: [
              const Spacer(),
              InkWell(
                  onTap: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const CreateAccount(),
                    ));
                  },
                  child: const Text('Create new account ?',
                      style: TextStyle(fontSize: 18))),
            ],
          ),
          const SizedBox(height: 20,),
        ]),
      ),
    );
  }

  Future singInWithGoogle()
  async {
    // begin auth interactive process
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

    // obtain auth details
    final GoogleSignInAuthentication auth = await gUser!.authentication;

    // create new credential for user
    final credentials = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken
    );

    // sing in
    return await FirebaseAuth.instance.signInWithCredential(credentials);
  }

  Future<void> initializeLocationAndSave() async {
    //device token
    // await AwesomeNotificationsFcm().requestFirebaseAppToken().then((value) {
    await FirebaseMessaging.instance.getToken().then((value) {
      debugPrint(
        "token is------ $value",
      );
      deviceToken = value!;

    });
  }
}
