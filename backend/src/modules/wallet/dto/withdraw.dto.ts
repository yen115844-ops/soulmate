import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsNumber, IsObject, IsOptional, Min, ValidateNested } from 'class-validator';

class BankInfoDto {
  @ApiProperty({ example: 'Vietcombank' })
  bankName: string;

  @ApiProperty({ example: '1234567890' })
  bankAccountNo: string;

  @ApiProperty({ example: 'NGUYEN VAN A' })
  bankAccountName: string;
}

export class WithdrawDto {
  @ApiProperty({ example: 500000, description: 'Amount to withdraw in VND' })
  @IsNumber()
  @Min(50000, { message: 'Số tiền rút tối thiểu là 50,000 VND' })
  amount: number;

  @ApiPropertyOptional({ description: 'Bank information (optional if already saved)' })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => BankInfoDto)
  bankInfo?: BankInfoDto;
}
