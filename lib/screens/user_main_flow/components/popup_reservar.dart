import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:orexi/components/rounded_button.dart';
import 'package:orexi/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PopupReservar extends StatefulWidget {
  final String nombreAlerta;
  final int cantidadAlerta;
  final int nuevoPrecio;
  final String idAlerta;

  const PopupReservar({
    Key key,
    @required this.nombreAlerta,
    @required this.cantidadAlerta,
    @required this.idAlerta,
    this.nuevoPrecio,
  }) : super(key: key);

  @override
  _PopupReservarState createState() => _PopupReservarState();
}

class _PopupReservarState extends State<PopupReservar> {
  static User user = FirebaseAuth.instance.currentUser;
  int _currentValue = 1;
  String _dropdownValue = "Efectivo";
  String _pickupTime = "Lo antes posible";
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(
        "Reservar " + widget.nombreAlerta,
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Padding(
        padding: EdgeInsets.all(8.0),
        child: Form(
          child: Column(
            children: <Widget>[
              Text(
                "Cantidad a reservar:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              new NumberPicker.integer(
                  initialValue: _currentValue,
                  minValue: 1,
                  maxValue: widget.cantidadAlerta,
                  onChanged: (newValue) =>
                      setState(() => _currentValue = newValue)),
              SizedBox(height: 20),
              Text(
                "Método de pago:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: _dropdownValue,
                onChanged: (String newValue) {
                  setState(() {
                    _dropdownValue = newValue;
                  });
                },
                items: <String>['Efectivo', 'Tarjeta crédito/débito']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Text(
                "¿Cuándo deseas recogerlo?",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: _pickupTime,
                onChanged: (String newValue) {
                  setState(() {
                    _pickupTime = newValue;
                  });
                },
                items: <String>[
                  'Lo antes posible',
                  'En media hora',
                  'En dos horas'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Container(
                width: 500,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(80),
                  child: RaisedButton(
                    onPressed: () async {
                      // Reservar y retornar _dropdownValue (metodo de pago) y
                      // _currentValue (cantidad)
                      DocumentSnapshot doc = await FirebaseFirestore.instance
                          .collection('producto')
                          .doc(widget.idAlerta)
                          .get();

                      String id_rest = doc["id_establecimiento"];

                      DocumentSnapshot rest = await FirebaseFirestore.instance
                          .collection('establecimiento')
                          .doc(id_rest)
                          .get();

                      FirebaseFirestore.instance
                          .collection('establecimiento')
                          .doc(id_rest)
                          .update({'num_ventas': rest['num_ventas'] + 1});

                      FirebaseFirestore.instance
                          .collection('producto')
                          .doc(widget.idAlerta)
                          .update({
                        'unidades': widget.cantidadAlerta - _currentValue
                      }).then((value) {
                        FirebaseFirestore.instance.collection('reserva').add({
                          'fecha': DateTime.now().toString(),
                          'producto': widget.idAlerta,
                          'medio_pago': _dropdownValue,
                          'unidades': _currentValue,
                          'tiempo_recogida': _pickupTime,
                          'id_establecimiento': id_rest,
                          'cliente': user.email,
                          'nombre': widget.nombreAlerta,
                          'precio': widget.nuevoPrecio == null
                              ? doc["precio"] * _currentValue
                              : widget.nuevoPrecio * _currentValue,
                          'estado': "En curso",
                        });
                      });
                      Navigator.pop(context);
                    },
                    color: green,
                    textColor: white,
                    child: Text(
                      "RESERVAR",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
