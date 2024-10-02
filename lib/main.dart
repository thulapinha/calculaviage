import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:share/share.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await getDatabase();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  Future<int> _getTripCount() async {
    final Database db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('trips');
    return maps.length;
  }

  Future<double> _getAverageFuelConsumption() async {
    final Database db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('trips');

    if (maps.isEmpty) return 0.0;

    double totalLiters = 0.0;
    double totalKilometers = 0.0;

    for (var trip in maps) {
      totalLiters += trip['total_litros'];
      totalKilometers += (trip['km_final'] - trip['km_inicial']);
    }

    return totalKilometers == 0 ? 0.0 :   totalKilometers / totalLiters ;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Check List Frota Capitali'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<int>(
              future: _getTripCount(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Erro ao carregar dados');
                } else {
                  return Text(
                    'Total de Puxadas: ${snapshot.data}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 20),
            FutureBuilder<double>(
              future: _getAverageFuelConsumption(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Erro ao carregar dados');
                } else {
                  return Text(
                    'Média de L/km: ${snapshot.data?.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AddTripDialog();
                  },
                );
              },
              child: Text('Adicionar Viagem'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryScreen()),
                );
              },
              child: Text('Histórico'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.amber[800],
        onTap: (index) {
          if (index == 0) {
            // Navegar para a tela Home
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          } else if (index == 1) {
            // Navegar para a tela Histórico
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HistoryScreen()),
            );
          }
        },
      ),
    );
  }
}

class AddTripDialog extends StatefulWidget {
  final Map<String, dynamic>? trip;

  AddTripDialog({this.trip});

  @override
  _AddTripDialogState createState() => _AddTripDialogState();
}

class _AddTripDialogState extends State<AddTripDialog> {
  final TextEditingController _driverController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _initialKmController = TextEditingController();
  final TextEditingController _finalKmController = TextEditingController();
  final TextEditingController _totalLitersController = TextEditingController();
  final TextEditingController _fisicoController = TextEditingController();
  final TextEditingController _financeiroController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.trip != null) {
      _driverController.text = widget.trip!['motorista'];
      _plateController.text = widget.trip!['placa'];
      _initialKmController.text = widget.trip!['km_inicial'].toString();
      _finalKmController.text = widget.trip!['km_final'].toString();
      _totalLitersController.text = widget.trip!['total_litros'].toString();
      _fisicoController.text = widget.trip!['fisico'].toString();
      _financeiroController.text = widget.trip!['financeiro'].toString();
      _selectedDate = DateTime.parse(widget.trip!['data']);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.trip == null ? 'Adicionar Viagem' : 'Editar Viagem'),
      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            TextField(
              controller: _driverController,
              decoration: InputDecoration(
                labelText: 'Motorista',
                prefixIcon: Icon(Icons.perm_contact_cal),
              ),
            ),
            TextField(
              controller: _plateController,
              decoration: InputDecoration(
                labelText: 'Placa',
                prefixIcon: Icon(Icons.fire_truck),
              ), inputFormatters: [
              FilteringTextInputFormatter.singleLineFormatter,
              PlacaVeiculoInputFormatter(),
            ],
            ),
            TextField(
              controller: _initialKmController,
              decoration: InputDecoration(
                labelText: 'KM Inicial',
                prefixIcon: Icon(Icons.gps_fixed),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _finalKmController,
              decoration: InputDecoration(
                labelText: 'KM Final',
                prefixIcon: Icon(Icons.route),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _totalLitersController,
              decoration: InputDecoration(
                labelText: 'Total de Litros',
                prefixIcon: Icon(Icons.local_gas_station),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _fisicoController,
              decoration: InputDecoration(
                labelText: 'Físico',
                prefixIcon: Icon(Icons.check_box_rounded),
              ),
            ),
            TextField(
              controller: _financeiroController,
              decoration: InputDecoration(
                labelText: 'Financeiro',
                prefixIcon: Icon(Icons.list_alt),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: <Widget>[
                Text(
                  _selectedDate == null
                      ? 'Data >>>'
                      : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: Text('Selecione Data'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () async {
            if (widget.trip == null) {
              // Salvar nova viagem no banco de dados
              await saveTrip(
                _driverController.text,
                _plateController.text,
                int.parse(_initialKmController.text),
                int.parse(_finalKmController.text),
                double.parse(_totalLitersController.text),
                _fisicoController.text,
                _financeiroController.text,
                DateTime.now(),
              );
            } else {
              // Atualizar viagem existente no banco de dados
              await updateTrip(
                widget.trip!['id'],
                _driverController.text,
                _plateController.text,
                int.parse(_initialKmController.text),
                int.parse(_finalKmController.text),
                double.parse(_totalLitersController.text),
                _fisicoController.text,
                _financeiroController.text,
                DateTime.now(),
              );
            }
            Navigator.of(context).pop();
          },
          child:
          Text(widget.trip == null ? 'Salvar Viagem' : 'Atualizar Viagem'),
        ),
      ],
    );
  }
}

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Viagens'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getTrips(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final trips = snapshot.data!;
          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return ListTile(
                title: Text('Motorista: ${trip['motorista']}'),
                subtitle: Text('Placa: ${trip['placa']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AddTripDialog(trip: trip);
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        await deleteTrip(trip['id']);
                        (context as Element).reassemble();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () {
                        shareTrip(trip);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> shareTrip(Map<String, dynamic> trip) async {
  final tripDetails = '''
  <<< *Detalhes da Viagem* >>>
  
*Data:* ${trip['data']}
*Motorista:* ${trip['motorista']}
*Placa:* ${trip['placa']}
*KM Inicial:* ${trip['km_inicial']}
*KM Final:* ${trip['km_final']}
*Total de Litros:* ${trip['total_litros']}
*Físico:* ${trip['fisico']}
*Financeiro:* ${trip['financeiro']}
*Total Percorrido:* ${calculateTotalDistance(
      trip['km_inicial'], trip['km_final'])} km
*Média por KM:* ${calculateAveragePerKm(
      trip['km_inicial'], trip['km_final'], trip['total_litros'])
      .toStringAsFixed(2)} L/km
''';

  Share.share(tripDetails, subject: 'Detalhes da Viagem');
}

Future<Database> getDatabase() async {
  return openDatabase(
    join(await getDatabasesPath(), 'trips.db'),
    onCreate: (db, version) {
      return db.execute(
          "CREATE TABLE trips(id INTEGER PRIMARY KEY, motorista TEXT, placa TEXT, km_inicial INTEGER, km_final INTEGER, total_litros REAL, fisico TEXT, financeiro TEXT, data TEXT)");
    },
    version: 1,
  );
}

Future<void> saveTrip(String motorista,
    String placa,
    int kmInicial,
    int kmFinal,
    double totalLitros,
    String fisico,
    String financeiro,
    DateTime data) async {
  final db = await getDatabase();
  await db.insert(
    'trips',
    {
      'motorista': motorista,
      'placa': placa,
      'km_inicial': kmInicial,
      'km_final': kmFinal,
      'total_litros': totalLitros,
      'fisico': fisico,
      'financeiro': financeiro,
      'data': data.toIso8601String(),
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> updateTrip(int id,
    String motorista,
    String placa,
    int kmInicial,
    int kmFinal,
    double totalLitros,
    String fisico,
    String financeiro,
    DateTime data) async {
  final db = await getDatabase();
  await db.update(
    'trips',
    {
      'motorista': motorista,
      'placa': placa,
      'km_inicial': kmInicial,
      'km_final': kmFinal,
      'total_litros': totalLitros,
      'fisico': fisico,
      'financeiro': financeiro,
      'data': data.toIso8601String(),
    },
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<void> deleteTrip(int id) async {
  final db = await getDatabase();
  await db.delete(
    'trips',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<List<Map<String, dynamic>>> getTrips() async {
  final db = await getDatabase();
  return db.query('trips');
}

double calculateTotalDistance(int kmInicial, int kmFinal) {
  return (kmFinal - kmInicial).toDouble();
}

double calculateAveragePerKm(int kmInicial, int kmFinal, double totalLitros) {
  final totalDistance = calculateTotalDistance(kmInicial, kmFinal);
  return totalDistance / totalLitros;
}
