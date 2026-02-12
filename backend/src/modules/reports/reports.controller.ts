import {
    Body,
    Controller,
    Delete,
    Get,
    HttpCode,
    HttpStatus,
    Param,
    Post,
    Put,
    Query,
    UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { CreateReportDto, ReportQueryDto, ResolveReportDto } from './dto';
import { ReportsService } from './reports.service';

@ApiTags('Reports')
@Controller('reports')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  // ==================== USER ENDPOINTS ====================

  @Post()
  @ApiOperation({ summary: 'Submit a report' })
  @ApiResponse({ status: 201, description: 'Report submitted' })
  async createReport(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateReportDto,
  ) {
    return this.reportsService.createReport(userId, dto);
  }

  @Get('my-reports')
  @ApiOperation({ summary: 'Get my submitted reports' })
  @ApiResponse({ status: 200, description: 'Reports retrieved' })
  async getMyReports(@CurrentUser('id') userId: string) {
    return this.reportsService.getMyReports(userId);
  }

  @Post('block/:userId')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Block a user' })
  @ApiResponse({ status: 200, description: 'User blocked' })
  async blockUser(
    @CurrentUser('id') blockerId: string,
    @Param('userId') blockedId: string,
  ) {
    return this.reportsService.blockUser(blockerId, blockedId);
  }

  @Delete('block/:userId')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Unblock a user' })
  @ApiResponse({ status: 200, description: 'User unblocked' })
  async unblockUser(
    @CurrentUser('id') blockerId: string,
    @Param('userId') blockedId: string,
  ) {
    return this.reportsService.unblockUser(blockerId, blockedId);
  }

  @Get('blocked-users')
  @ApiOperation({ summary: 'Get my blocked users list' })
  @ApiResponse({ status: 200, description: 'Blocked users retrieved' })
  async getBlockedUsers(@CurrentUser('id') userId: string) {
    return this.reportsService.getBlockedUsers(userId);
  }

  // ==================== ADMIN ENDPOINTS ====================

  @Get('admin/list')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: Get all reports' })
  async adminGetReports(@Query() query: ReportQueryDto) {
    return this.reportsService.adminGetReports(query);
  }

  @Put('admin/:id/resolve')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Admin: Resolve a report' })
  async adminResolveReport(
    @Param('id') id: string,
    @CurrentUser('id') adminId: string,
    @Body() dto: ResolveReportDto,
  ) {
    return this.reportsService.adminResolveReport(id, adminId, dto);
  }
}
