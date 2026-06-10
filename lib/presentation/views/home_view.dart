import 'package:flutter/material.dart';

import 'pacientes_view.dart';
import 'citas_view.dart';

class HomeView extends StatefulWidget {

  const HomeView({super.key});

  @override
  State<HomeView> createState() =>
      _HomeViewState();
}

class _HomeViewState
    extends State<HomeView> {

  int paginaActual = 0;

  final paginas = [

    const PacientesView(),

    const CitasView(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: paginas[paginaActual],

      bottomNavigationBar:
          BottomNavigationBar(

        currentIndex:
            paginaActual,

        onTap: (index) {

          setState(() {

            paginaActual = index;
          });
        },

        items: const [

          BottomNavigationBarItem(

            icon: Icon(
              Icons.people,
            ),

            label: 'Pacientes',
          ),

          BottomNavigationBarItem(

            icon: Icon(
              Icons.calendar_month,
            ),

            label: 'Citas',
          ),
        ],
      ),
    );
  }
}