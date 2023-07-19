// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:dayflow/components/radioWidget.dart';
import 'package:dayflow/components/textHeadingStyle.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class addTaskModal extends StatelessWidget {
  const addTaskModal({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(30),
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), color: Color(0xFFEDF3FC)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              'Add A Task',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF234EF3)),
            ),
          ),
          Gap(12),
          Divider(
            thickness: 1.2,
            color: Colors.blue.shade100,
          ),
          Gap(12),
          Text(
            'Task Name',
            style: textHeadingStyle.textStyle,
          ),
          Gap(12),
          TextField(
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              hintText: 'Add a name for your task',
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue.shade100),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Gap(12),
          Text(
            'Description',
            style: textHeadingStyle.textStyle,
          ),
          Gap(12),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              hintText: 'Add a description for your task',
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue.shade100),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Gap(12),
          Text(
            'Category',
            style: textHeadingStyle.textStyle,
          ),
          Gap(12),
          Row(
            children: [
              Expanded(
                child: radioWidget(
                  categoryColor: Colors.red,
                  titleRadio: 'Work',
                ),
              ),
              Expanded(
                child: radioWidget(
                  categoryColor: Colors.blue,
                  titleRadio: 'School',
                ),
              ),
              Expanded(
                child: radioWidget(
                  categoryColor: Colors.green,
                  titleRadio: 'Person',
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
