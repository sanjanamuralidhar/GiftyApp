abstract class TestEvent{} 

class ChangeSomeValues extends TestEvent {
  final int data;

  ChangeSomeValues(this.data);
}