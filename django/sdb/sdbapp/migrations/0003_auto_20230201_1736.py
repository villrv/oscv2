# Generated by Django 3.2.16 on 2023-02-01 17:36

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('sdbapp', '0002_auto_20230201_1639'),
    ]

    operations = [
        migrations.AlterField(
            model_name='sdbentry',
            name='dec',
            field=models.CharField(max_length=32, null=True),
        ),
        migrations.AlterField(
            model_name='sdbentry',
            name='ra',
            field=models.CharField(max_length=32, null=True),
        ),
    ]