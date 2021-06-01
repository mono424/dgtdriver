abstract class Answer<T> {
  int code;
  T process(List<int> msg);
}