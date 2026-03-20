# Services Feature — Design

**Data:** 2026-03-12

## Contexto

Implementar a aba de Serviços no app Flutter (Scheduler). O prestador deve poder listar, criar, editar, desativar e deletar serviços. Um serviço pode ser associado (opcionalmente) a um agendamento, preenchendo automaticamente a duração.

---

## Modelo de Dados

### ServiceModel
```dart
class ServiceModel {
  final String id;
  final String name;
  final String? description;
  final double? price;
  final int? durationMinutes;
  final bool isActive;
}
```

### ServiceRepository — endpoints
```
GET    /businesses/:businessId/services        → listAll
POST   /businesses/:businessId/services        → create
PATCH  /businesses/:businessId/services/:id    → update
DELETE /businesses/:businessId/services/:id    → delete
```
Usa `business.id` (UUID) como `businessId`. Segue padrão ApiClient com envelope unwrapping.

---

## Arquitetura: ServicesBloc global

`ServicesBloc` providenciado em `main.dart`, ao lado de `AppointmentsBloc` e `BusinessBloc`.

Quando `BusinessBloc` emite novo negócio, `BlocListener` dispara `ServicesLoadRequested` (mesmo padrão existente).

### Events
```
ServicesLoadRequested(businessId)
ServiceCreateRequested(businessId, name, price?, durationMinutes?)
ServiceUpdateRequested(businessId, serviceId, name?, price?, durationMinutes?, isActive?)
ServiceDeleteRequested(businessId, serviceId)
```

### States
```
ServicesInitial
ServicesLoading
ServicesLoaded(services: List<ServiceModel>)
ServicesActionInProgress(services: List<ServiceModel>)
ServicesError(message, services?: List<ServiceModel>)
```

---

## UI: Aba de Serviços

- **Lista de cards**: nome + badge preço + duração
- Serviços inativos: opacidade reduzida + badge "Inativo" + opção de reativar
- **FAB (+)**: abre BottomSheet com formulário (criar/editar)
- **Formulário**: nome (obrigatório), preço (opcional), duração em minutos (opcional)
- **Deletar**: AlertDialog de confirmação
- **Estado vazio**: mensagem + botão para adicionar

---

## UI: Seletor no Formulário de Agendamento

- Dropdown "Serviço (opcional)" acima do campo de nome do cliente
- Ao selecionar: preenche duração automaticamente (se `durationMinutes` presente)
- Ao limpar: duração volta ao padrão (60 min)
- `serviceId: String?` adicionado ao `ScheduleAppointmentCreateRequested`
- Se lista vazia ou loading: dropdown desabilitado silenciosamente
