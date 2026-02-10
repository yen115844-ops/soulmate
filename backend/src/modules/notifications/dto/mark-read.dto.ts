import { IsArray, IsOptional, IsString, IsUUID } from 'class-validator';

export class MarkReadDto {
  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  ids?: string[];
}

export class MarkSingleReadDto {
  @IsString()
  @IsUUID('4')
  id: string;
}
