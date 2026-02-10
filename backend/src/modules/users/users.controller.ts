import {
    BadRequestException,
    Body,
    Controller,
    Delete,
    Get,
    HttpCode,
    HttpStatus,
    Param,
    Patch,
    Post,
    Put,
    Query,
    UploadedFile,
    UseGuards,
    UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { PaginationDto } from '../../common/dto/pagination.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AdminKycQueryDto, AdminUserQueryDto, CreateEmergencyContactDto, ReviewKycDto, SubmitKycDto, UpdateEmergencyContactDto, UpdateLocationDto, UpdateProfileDto, UpdateSettingsDto, UpdateUserStatusDto } from './dto';
import { UsersService } from './users.service';

@ApiTags('Users')
@Controller('users')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // ==================== ADMIN ENDPOINTS ====================

  @Get('admin/stats')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: Get user statistics' })
  @ApiResponse({ status: 200, description: 'User stats retrieved' })
  async adminGetStats() {
    return this.usersService.adminGetUserStats();
  }

  @Get('admin/list')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: Get all users with filters' })
  @ApiResponse({ status: 200, description: 'Users list retrieved' })
  async adminGetUsers(@Query() query: AdminUserQueryDto) {
    return this.usersService.adminGetAllUsers(query);
  }

  @Patch('admin/:id/status')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Admin: Update user status' })
  @ApiResponse({ status: 200, description: 'User status updated' })
  async adminUpdateStatus(
    @Param('id') id: string,
    @Body() dto: UpdateUserStatusDto,
  ) {
    return this.usersService.adminUpdateUserStatus(id, dto);
  }

  // ==================== KYC ADMIN ENDPOINTS ====================

  @Get('admin/kyc/stats')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: Get KYC statistics' })
  @ApiResponse({ status: 200, description: 'KYC stats retrieved' })
  async adminGetKycStats() {
    return this.usersService.adminGetKycStats();
  }

  @Get('admin/kyc/list')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: Get all KYC verifications' })
  @ApiResponse({ status: 200, description: 'KYC list retrieved' })
  async adminGetKycList(@Query() query: AdminKycQueryDto) {
    return this.usersService.adminGetAllKyc(query);
  }

  @Get('admin/kyc/:id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: Get KYC by ID' })
  @ApiResponse({ status: 200, description: 'KYC details retrieved' })
  async adminGetKycById(@Param('id') id: string) {
    return this.usersService.adminGetKycById(id);
  }

  @Patch('admin/kyc/:id/review')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Admin: Review KYC (approve/reject)' })
  @ApiResponse({ status: 200, description: 'KYC reviewed successfully' })
  async adminReviewKyc(
    @Param('id') id: string,
    @CurrentUser('id') adminId: string,
    @Body() dto: ReviewKycDto,
  ) {
    return this.usersService.adminReviewKyc(id, adminId, dto);
  }

  // ==================== USER ENDPOINTS ====================

  @Get('profile')
  @ApiOperation({ summary: 'Get current user profile' })
  @ApiResponse({ status: 200, description: 'Profile retrieved' })
  async getMyProfile(@CurrentUser('id') userId: string) {
    return this.usersService.getProfile(userId);
  }

  @Put('profile')
  @ApiOperation({ summary: 'Update current user profile' })
  @ApiResponse({ status: 200, description: 'Profile updated' })
  async updateMyProfile(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateProfileDto,
  ) {
    return this.usersService.updateProfile(userId, dto);
  }

  @Post('profile/avatar')
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({ summary: 'Upload/update avatar' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
        },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'Avatar updated successfully' })
  async updateAvatar(
    @CurrentUser('id') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }
    return this.usersService.updateAvatar(userId, file);
  }

  @Put('location')
  @ApiOperation({ summary: 'Update current user location' })
  @ApiResponse({ status: 200, description: 'Location updated' })
  async updateMyLocation(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateLocationDto,
  ) {
    return this.usersService.updateLocation(userId, dto);
  }

  @Get('profile/stats')
  @ApiOperation({ summary: 'Get current user profile statistics' })
  @ApiResponse({ status: 200, description: 'Profile stats retrieved' })
  async getProfileStats(@CurrentUser('id') userId: string) {
    return this.usersService.getProfileStats(userId);
  }

  // ==================== USER SETTINGS ====================

  @Get('settings')
  @ApiOperation({ summary: 'Get current user settings' })
  @ApiResponse({ status: 200, description: 'Settings retrieved' })
  async getSettings(@CurrentUser('id') userId: string) {
    return this.usersService.getSettings(userId);
  }

  @Put('settings')
  @ApiOperation({ summary: 'Update current user settings' })
  @ApiResponse({ status: 200, description: 'Settings updated' })
  async updateSettings(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateSettingsDto,
  ) {
    return this.usersService.updateSettings(userId, dto);
  }

  @Get('favorites')
  @ApiOperation({ summary: 'Get favorite partners' })
  @ApiResponse({ status: 200, description: 'Favorites retrieved' })
  async getFavorites(
    @CurrentUser('id') userId: string,
    @Query() paginationDto: PaginationDto,
  ) {
    return this.usersService.getFavorites(userId, paginationDto);
  }

  @Post('favorites/:partnerId')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Add partner to favorites' })
  @ApiResponse({ status: 200, description: 'Added to favorites' })
  async addFavorite(
    @CurrentUser('id') userId: string,
    @Param('partnerId') partnerId: string,
  ) {
    return this.usersService.addFavorite(userId, partnerId);
  }

  @Delete('favorites/:partnerId')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Remove partner from favorites' })
  @ApiResponse({ status: 200, description: 'Removed from favorites' })
  async removeFavorite(
    @CurrentUser('id') userId: string,
    @Param('partnerId') partnerId: string,
  ) {
    return this.usersService.removeFavorite(userId, partnerId);
  }

  // ==================== EMERGENCY CONTACTS ====================

  @Get('emergency-contacts')
  @ApiOperation({ summary: 'Get emergency contacts' })
  @ApiResponse({ status: 200, description: 'Emergency contacts retrieved' })
  async getEmergencyContacts(@CurrentUser('id') userId: string) {
    return this.usersService.getEmergencyContacts(userId);
  }

  @Post('emergency-contacts')
  @ApiOperation({ summary: 'Add emergency contact' })
  @ApiResponse({ status: 201, description: 'Emergency contact created' })
  async createEmergencyContact(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateEmergencyContactDto,
  ) {
    return this.usersService.createEmergencyContact(userId, dto);
  }

  @Put('emergency-contacts/:id')
  @ApiOperation({ summary: 'Update emergency contact' })
  @ApiResponse({ status: 200, description: 'Emergency contact updated' })
  async updateEmergencyContact(
    @CurrentUser('id') userId: string,
    @Param('id') contactId: string,
    @Body() dto: UpdateEmergencyContactDto,
  ) {
    return this.usersService.updateEmergencyContact(userId, contactId, dto);
  }

  @Delete('emergency-contacts/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete emergency contact' })
  @ApiResponse({ status: 200, description: 'Emergency contact deleted' })
  async deleteEmergencyContact(
    @CurrentUser('id') userId: string,
    @Param('id') contactId: string,
  ) {
    return this.usersService.deleteEmergencyContact(userId, contactId);
  }

  // ==================== BLOCK USER ====================

  @Post('block/:userId')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Block a user' })
  @ApiResponse({ status: 200, description: 'User blocked successfully' })
  @ApiResponse({ status: 400, description: 'Cannot block yourself' })
  async blockUser(
    @CurrentUser('id') userId: string,
    @Param('userId') blockedUserId: string,
  ) {
    return this.usersService.blockUser(userId, blockedUserId);
  }

  @Delete('block/:userId')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Unblock a user' })
  @ApiResponse({ status: 200, description: 'User unblocked successfully' })
  async unblockUser(
    @CurrentUser('id') userId: string,
    @Param('userId') blockedUserId: string,
  ) {
    return this.usersService.unblockUser(userId, blockedUserId);
  }

  @Get('blocked/list')
  @ApiOperation({ summary: 'Get list of blocked users' })
  @ApiResponse({ status: 200, description: 'Blocked users retrieved' })
  async getBlockedUsers(@CurrentUser('id') userId: string) {
    return this.usersService.getBlockedUsers(userId);
  }

  // ==================== USER KYC ====================

  @Get('kyc')
  @ApiOperation({ summary: 'Get my KYC status' })
  @ApiResponse({ status: 200, description: 'KYC status retrieved' })
  async getMyKycStatus(@CurrentUser('id') userId: string) {
    return this.usersService.getKycStatus(userId);
  }

  @Post('kyc')
  @ApiOperation({ summary: 'Submit KYC verification' })
  @ApiResponse({ status: 201, description: 'KYC submitted' })
  @ApiResponse({ status: 400, description: 'KYC already verified or pending' })
  async submitKyc(
    @CurrentUser('id') userId: string,
    @Body() dto: SubmitKycDto,
  ) {
    return this.usersService.submitKyc(userId, dto);
  }

  // Admin routes
  @Get()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Get all users (Admin only)' })
  @ApiQuery({ name: 'role', required: false, enum: UserRole })
  @ApiQuery({ name: 'search', required: false })
  @ApiResponse({ status: 200, description: 'Users list retrieved' })
  async findAll(
    @Query() paginationDto: PaginationDto,
    @Query('role') role?: UserRole,
    @Query('search') search?: string,
  ) {
    return this.usersService.findAll(paginationDto, { role, search });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get user by ID' })
  @ApiResponse({ status: 200, description: 'User retrieved' })
  @ApiResponse({ status: 404, description: 'User not found' })
  @ApiResponse({ status: 403, description: 'User is blocked' })
  async findOne(
    @Param('id') id: string,
    @CurrentUser('id') currentUserId: string,
  ) {
    return this.usersService.findById(id, currentUserId);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete user (Admin only)' })
  @ApiResponse({ status: 200, description: 'User deleted' })
  async delete(@Param('id') id: string) {
    return this.usersService.delete(id);
  }
}
