import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'TextFieldWidget.dart';

class AddNewTaskModel extends StatelessWidget {
  const AddNewTaskModel({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(30),
      height: MediaQuery.of(context).size.height * 0.70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              'New Entry',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF234EF3)),
            ),
          ),
          Divider(
            thickness: 1.5,
            color: Colors.grey.shade200,
          ),
          Gap(12),
          Text(
            'Today\'s tasks',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF234EF3),
            ),
          ),
          Gap(6),
          TextFieldWidget(
            hintText: 'Add a Task',
            maxLines: 1,
          ),
          Gap(12),
          Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF234EF3),
            ),
          ),
          Gap(6),
          TextFieldWidget(
            hintText: 'Enter a description',
            maxLines: 3,
          ),
          Gap(12),
          Text(
            'Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF234EF3),
            ),
          ),
          RadioListTile(
            title: Text('New Task'),
            value: 1,
            groupValue: 0,
            onChanged: (value) {},
          )
        ],
      ),
    );
  }
}
