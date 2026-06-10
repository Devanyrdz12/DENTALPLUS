import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_generative_ai/google_generative_ai.dart'; 
import 'package:flutter_markdown/flutter_markdown.dart'; // <-- EL NUEVO MOTOR GRÁFICO MARKDOWN

class GeminiBotWidget extends StatefulWidget {
  final bool isDentist;

  const GeminiBotWidget({super.key, required this.isDentist});

  @override
  State<GeminiBotWidget> createState() => _GeminiBotWidgetState();
}

class _GeminiBotWidgetState extends State<GeminiBotWidget> {
  final List<Map<String, String>> _historialUI = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  
  // ⚠️ PON TU API KEY AQUÍ DE NUEVO ⚠️
  final String _apiKey = "AQ.Ab8RN6JrfBStzDguH1b05wqAtPdLiEr70K-1zIgvvf4zrOHPVQ"; 
  
  late GenerativeModel _model;
  late ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _inicializarBot();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _inicializarBot() {
    final instrucciones = widget.isDentist
        ? "Actúas como un asistente dental experto de IA de nivel Senior para el dentista. Ayudas a optimizar diagnósticos, responder dudas clínicas rápido, calcular interpretaciones financieras y resumir expedientes. Mantén respuestas profesionales, cortas, estructuradas y al grano. Usa formato Markdown (negritas, listas, etc) para que sea fácil de leer."
        : "Actúas como un asistente médico dental empático. Escucha los síntomas del paciente y dale una recomendación breve. Al final de tu respuesta, SIEMPRE debes generar un resumen técnico del problema dentro de un bloque de código markdown (```). Escribe 'TEXTO PARA COPIAR Y PEGAR:' justo antes del bloque.";

    _model = GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(instrucciones),
    );

    _chat = _model.startChat();

    String saludo = widget.isDentist
        ? "Hola Doctor. Soy su asistente clínico de IA. ¿En qué diagnóstico o gestión financiera le puedo ayudar hoy?"
        : "Hola. Cuéntame qué síntomas tienes o qué molestia sientes, y te armaré el texto perfecto para solicitar tu consulta.";
    _historialUI.add({"role": "model", "text": saludo});
  }

  Future<void> _enviarMensaje(StateSetter updateModal) async {
    if (_chatController.text.trim().isEmpty || _isLoading) return;

    final userText = _chatController.text.trim();
    
    setState(() {
      _historialUI.add({"role": "user", "text": userText});
      _isLoading = true;
    });
    updateModal(() {}); 
    
    _chatController.clear(); 
    _irAlFondo();

    try {
      final response = await _chat.sendMessage(Content.text(userText));
      
      if (response.text != null) {
        setState(() {
          _historialUI.add({"role": "model", "text": response.text!});
        });
      }
    } catch (e) {
      setState(() {
        _historialUI.add({"role": "model", "text": "Error de conexión: Verifica tu API Key o conexión a internet. Detalles: $e"});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      updateModal(() {}); 
      _irAlFondo();
    }
  }

  void _irAlFondo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- MOTOR DE RENDERIZADO VISUAL CON SOPORTE MARKDOWN ---
  Widget _buildMensaje(String text, bool isUser, BuildContext context) {
    // Si es el usuario o no hay bloques de código de copiado, renderizamos todo como Markdown hermoso
    if (isUser || !text.contains('```')) {
      return MarkdownBody(
        data: text,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(fontSize: 14),
          strong: const TextStyle(fontWeight: FontWeight.bold),
          listBullet: const TextStyle(fontSize: 14),
        ),
      );
    }

    // Si la IA manda bloques de código (para el paciente), separamos el Markdown del código de terminal
    List<Widget> widgets = [];
    final parts = text.split('```');
    
    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 0) {
        // Texto normal renderizado como Markdown
        if (parts[i].trim().isNotEmpty) {
          widgets.add(
            MarkdownBody(
              data: parts[i].trim(),
              selectable: true,
              styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 14)),
            )
          );
          widgets.add(const SizedBox(height: 8));
        }
      } else {
        // Bloque de código de la terminal (El texto limpio a copiar)
        String cleanCode = parts[i].replaceFirst(RegExp(r'^[a-zA-Z]+\n'), '').trim();
        
        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade800, 
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.isDentist ? Colors.blue : Colors.teal, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  cleanCode, 
                  style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 13),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isDentist ? Colors.blue : Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: cleanCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('¡Bloque copiado! 📋 Listo para pegar.'), 
                          backgroundColor: widget.isDentist ? Colors.blue : Colors.teal,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('Copiar este bloque', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        );
        widgets.add(const SizedBox(height: 8));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  void _abrirPanelChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology, color: widget.isDentist ? Colors.blue : Colors.teal, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            widget.isDentist ? "Asistente Dental IA" : "Sintomatología IA",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  const Divider(),
                  
                  Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _historialUI.length,
                      itemBuilder: (context, index) {
                        final msg = _historialUI[index];
                        final isUser = msg["role"] == "user";
                        
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 8, bottom: 2),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? (widget.isDentist ? Colors.blue.shade100 : Colors.teal.shade50)
                                      : Colors.transparent, 
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _buildMensaje(msg["text"]!, isUser, context),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(child: LinearProgressIndicator(color: widget.isDentist ? Colors.blue : Colors.teal)),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: const InputDecoration(
                            hintText: "Escribe aquí tu consulta...",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _enviarMensaje(setModalState), 
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.send, color: widget.isDentist ? Colors.blue : Colors.teal),
                        onPressed: () => _enviarMensaje(setModalState), 
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "gemini_bot_hero_${widget.isDentist ? 'dr' : 'pac'}",
      backgroundColor: widget.isDentist ? Colors.blueAccent : Colors.teal,
      foregroundColor: Colors.white,
      elevation: 6,
      onPressed: _abrirPanelChat,
      child: const Icon(Icons.smart_toy, size: 28),
    );
  }
}