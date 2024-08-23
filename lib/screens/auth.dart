import 'dart:io';

import 'package:chat_app/widgets/user_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _fromKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredUserName = '';
  var _enteredPassword = '';
  File? _selectedImageFile;
  var _isUpLoading = false;

  void _submit() async{
   final valid = _fromKey.currentState!.validate();
   if(!valid || (!_isLogin && _selectedImageFile == null)) {
     return;
   }
   try{
     setState(() {
       _isUpLoading = true;
     });
   if(_isLogin){
     final UserCredential userCredential = await _firebase.signInWithEmailAndPassword(
         email: _enteredEmail,
         password: _enteredPassword,
     );
   }else{

       final UserCredential userCredential = await _firebase.createUserWithEmailAndPassword(
         email: _enteredEmail,
         password: _enteredPassword,
       );

    final Reference storageRef =   FirebaseStorage.instance
        .ref()
        .child('user_images')
        .child('{$userCredential.user!.uid}.jpg');
      await  storageRef.putFile(_selectedImageFile!);
       final imageUrl = await      storageRef.getDownloadURL();

      await FirebaseFirestore.instance
           .collection('users')
           .doc(userCredential.user!.uid)
           .set({
         'userName': _enteredUserName,
         'email': _enteredEmail,
         'image_url' : imageUrl,

       });
     }
     }
   on FirebaseAuthException catch(e){
     ScaffoldMessenger.of(context).clearSnackBars();
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text(e.message?? 'Authentication failed'),
     ),
     );
     setState(() {
       _isUpLoading = false;
     });
     }



     _fromKey.currentState!.save();

  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(
                  bottom: 30,
                  top: 20,
                  right: 20,
                  left: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: EdgeInsets.all(20),
                 child: SingleChildScrollView(
                   child: Padding(padding: EdgeInsets.all(16),
                     child: Form(
                       key: _fromKey,
                       child: Column(children: [

                       if(!_isLogin)  UserImagePicker(onPickImage: (File pickedImage) {
                         _selectedImageFile = pickedImage;
                       },),

                         TextFormField(decoration: InputDecoration(
                           labelText: 'Email Address',
                         ),
                           onSaved: (value) => _enteredEmail = value!,
                           keyboardType: TextInputType.emailAddress,
                           autocorrect: false,
                           textCapitalization: TextCapitalization.none,
                           validator: (value){
                           if(value == null || value.trim().isEmpty || !value.contains('@')){
                                  return 'Please enter a valid email address';
                           }
                            return null;
                           },
                         ),
                         SizedBox(height: 16,),
                         if(!_isLogin)
                         TextFormField(decoration: InputDecoration(
                           labelText: 'User Name',
                         ),
                           onSaved: (value) => _enteredUserName = value!,

                           validator: (value){
                             if(value == null || value.trim().length<4 ){
                               return 'Please enter at least 4 characters';
                             }
                             return null;
                           },
                         ),
                         SizedBox(height: 16,),

                         TextFormField(decoration: InputDecoration(
                           labelText: 'Password',
                         ),
                           onSaved: (value) => _enteredPassword = value!,
                         obscureText: true,
                           validator: (value){
                             if(value == null || value.trim().length<6){
                               return 'Password must be at least 6 characters long';
                             }
                             return null;
                           },
                         ),
                         SizedBox(height: 16,),
                         if(_isUpLoading)
                           CircularProgressIndicator(),

                         if(!_isUpLoading)
                         ElevatedButton(
                             onPressed:_submit,
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                           ),
                             child: Text(_isLogin? 'Login': 'Signup' ),
                         ),
                         if(!_isUpLoading)
                         TextButton(
                           onPressed: (){
                             setState(() {
                               _isLogin = ! _isLogin;
                             });
                           },

                           child: Text(_isLogin?
                           'Create an account':
                           'I already have an account' ),
                         ),

                       ],),
                     ),
                   ),
                 ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
