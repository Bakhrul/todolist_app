class TodoAction {
    int id;
    int todo;
    String title;
    DateTime created;
    dynamic done;
    dynamic valid;

    TodoAction({
        this.id,
        this.title,
        this.created,
        this.done,
        this.valid
    });
}