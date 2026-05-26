import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/entities/task.dart';
import '../domain/entities/task_priority.dart';
import '../domain/entities/task_status.dart';
import '../presentation/bloc/task_bloc.dart';
import '../presentation/bloc/task_event.dart';
import '../presentation/bloc/task_state.dart';
import '../presentation/widgets/task_form_fields.dart';

class CreateTaskScreen extends StatefulWidget {
  final Task? initialTask;

  const CreateTaskScreen({Key? key, this.initialTask}) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskPriority _priority;
  DateTime? _deadline;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _deadline = task?.deadline;
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a deadline for the task.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final task = Task(
      id: widget.initialTask?.id ??
          'task-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: widget.initialTask?.status ?? TaskStatus.pending,
      priority: _priority,
      deadline: _deadline!,
      createdAt: widget.initialTask?.createdAt ?? DateTime.now(),
    );

    final bloc = context.read<TaskBloc>();
    bloc.add(widget.initialTask == null ? CreateTask(task) : UpdateTask(task));

    await bloc.stream.firstWhere((state) => state is! TaskLoading);
    if (!mounted) return;

    setState(() => _isSaving = false);
    final state = context.read<TaskBloc>().state;
    if (state is TaskError) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.message)));
      return;
    }

    context.pop();
  }

  Future<void> _pickDeadline() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text(widget.initialTask == null ? 'Create Task' : 'Edit Task'),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.initialTask == null
                                ? 'New Task'
                                : 'Edit Task',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Briefly describe what needs to be completed and when.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          TaskFormFields(
                            titleController: _titleController,
                            descriptionController: _descriptionController,
                            selectedPriority: _priority,
                            selectedDeadline: _deadline,
                            onPriorityChanged: (value) {
                              if (value != null) {
                                setState(() => _priority = value);
                              }
                            },
                            onPickDeadline: _pickDeadline,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSaving ? null : _onSave,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(widget.initialTask == null
                          ? 'Create Task'
                          : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.16),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
