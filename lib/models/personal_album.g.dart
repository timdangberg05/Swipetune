// GENERATED CLAUDE CODE - DO NOT MODIFY BY HAND

part of 'personal_album.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PersonalAlbumAdapter extends TypeAdapter<PersonalAlbum> {
  @override
  final int typeId = 0;

  @override
  PersonalAlbum read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PersonalAlbum(
      name: fields[0] as String,
      trackIds: (fields[1] as List).cast<String>(),
      coverImageUrl: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PersonalAlbum obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.trackIds)
      ..writeByte(2)
      ..write(obj.coverImageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalAlbumAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
