# RxStore

RxStore is a stream-based Redux implementation with support for side-effects.

## Concepts

The store contains all the state of your app which cannot be changed directly. In order to change the state, you need to dispatch an action, which is just data. You can see an action as a breadcrumb explaining why something changed. A reducer is a function that takes an action and the current state and returns the next state. The store then emits the new state to its subscribers.

Reducers are pure functions and are synchronous. Handle asynchronous tasks and side-effects in epics. An epic is a function that takes an action and the current state and returns a stream of actions. Epics cannot change the state, but can return other actions that are handled by a reducer that can change the state. This makes debugging a lot easier.

## State

First, define the state of your app. It is recommended to make the state immutable by using a library like [built_value](https://pub.dev/packages/built_value) or [freezed](https://pub.dev/packages/freezed), but to keep things simple we'll use plain Dart:

```dart
class AppState {
  AppState({required this.toDoList, required this.showCompleted});

  final List<ToDo> toDoList;
  final bool showCompleted;
}

class ToDo {
  ToDo({required this.text, required this.completed});

  final String text;
  final bool completed;
}
```

## Actions

An action is an object that describes what happened. It is just data, without logic. Here is a simple action to add a new to do item to the list:

```dart
class AddToDo implements Action {
  AddToDo({required this.text});

  final String text;
}
```

## Reducers

A reducer is the only way to update the state. It takes the current state and an action as arguments and returns the next state. Because reducers are pure functions, they are easy to test and debug.

```dart
AppState reducer(AppState state, Action action) {
  if (action is AddToDo) {
    return AppState(
        toDoList: [...state.toDoList, ToDo(text: action.text, completed: false)], showCompleted: state.showCompleted);
  }

  return state;
}
```

## Epics

An epic is used for asynchronous tasks, like calling a REST endpoint or reading a file. Like a reducer it takes the current state and an action as arguments but unlike a reducer it returns a stream of actions. These actions are passes again to all reducers and epics, so make sure to only handle the actions you're interested in to avoid writing a loop.

```dart
// Create an epic that only responds to FetchToDoList actions and then calls _fetchToDoList
Stream<Action> epic(Stream<Action> actions, ValueStream<AppState> state) =>
  actions.whereType<FetchToDoList>() // Filter on FetchToDoList actions
         .switchMap((FetchToDoList action) => _fetchToDoList(action));

Stream<Action> _fetchToDoList(FetchToDoList action) async* {
  yield const FetchingToDoList(); // A reducer can set a loading flag to true

  // Make an asynchronous call to the server
  final response = await client.fetchToDoList());
  if (response.statusCode == HttpStatus.ok) {
      // All ok, return an action with the list
      yield FetchedToDoList(list: response.items, error: null);
    } else {
      // Something went wrong, return an action detailing what went wrong
      yield FetchedToDoList(list: null, error: 'Something went wrong');
    }
  }
```

## Store

The store ties the state, the reducer and optionally the epic together.

To create a store you must at least pass a reducer and the initial state:

```dart
final store = Store<AppState>(
  reducer,
  initialState: AppState(toDoList: [], showCompleted: true),
);
```

If you have an epic, pass it to the constructor like this:

```dart
final store = Store<AppState>(
  reducer,
  initialState: AppState(toDoList: [], showCompleted: true),
  epic: epic,
);
```

## Listening to the store

The store exposes a stream that always emits the latest state. You can use this to react to changes in the state.

The moment you subscribe you will get the current state, even if the state didn't change in the meantime.

```dart
store.state.listen(print);
```

## How can I define multiple reducers/epics?

The library ships with two helper functions to do exactly that, `combineReducers` and `combineEpics`: 

```dart
final rootReducer = combineReducers([reducerOne, reducerTwo, reducerThree]);
final rootEpic = combineEpics([epicOne, epicTwo, epicThree]);
```

The functions return a normal reducer and epic respectively which you can again use in another combine call or pass to the store.

## Help! I wrote a loop...

Every action returned by an epic is also received again by the same epic. As long as you don't return the same type of action that the epic is handling, you won't introduce any loops.

```dart
// Infinite loop: handling and returning all actions
Stream<Action> epic(Stream<Action> actions, ValueStream<AppState> state) => actions;

// Infinite loop: filtering on a type but still returning the same type
Stream<Action> epic(Stream<Action> actions, ValueStream<AppState> state) => 
  actions.whereType<FetchToDoList>();

// No loop: handling actions of type FetchToDoList but returning FetchingToDoList
Stream<Action> epic(Stream<Action> actions, ValueStream<AppState> state) =>
  actions.whereType<FetchToDoList>()
         .switchMap((FetchToDoList action) => const FetchingToDoList());
```

## Inspiration

- [redux](https://pub.dev/packages/redux)
- [flutter_redux](https://pub.dev/packages/flutter_redux)
- [redux_thunk](https://pub.dev/packages/redux_thunk)
