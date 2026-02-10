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
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import {
    CreateDistrictDto,
    CreateInterestCategoryDto,
    CreateInterestDto,
    CreateLanguageDto,
    CreateProvinceDto,
    CreateServiceTypeDto,
    CreateTalentCategoryDto,
    CreateTalentDto,
    UpdateDistrictDto,
    UpdateInterestDto,
    UpdateLanguageDto,
    UpdateProvinceDto,
    UpdateServiceTypeDto,
    UpdateTalentDto,
} from './dto';
import { MasterDataService } from './master-data.service';

@ApiTags('Master Data')
@Controller('master-data')
export class MasterDataController {
  constructor(private readonly masterDataService: MasterDataService) {}

  // ==================== Public Endpoints (No Auth) ====================

  @Get('profile')
  @ApiOperation({ summary: 'Get all master data for profile editing (public)' })
  @ApiResponse({ status: 200, description: 'Master data retrieved' })
  async getProfileMasterData() {
    return this.masterDataService.getProfileMasterData();
  }

  @Get('partner')
  @ApiOperation({ summary: 'Get all master data for partner registration (public)' })
  @ApiResponse({ status: 200, description: 'Partner master data retrieved' })
  async getPartnerMasterData() {
    return this.masterDataService.getPartnerMasterData();
  }

  @Get('service-types')
  @ApiOperation({ summary: 'Get all service types (public)' })
  @ApiQuery({ name: 'includeInactive', required: false, type: Boolean })
  async getServiceTypes(@Query('includeInactive') includeInactive?: string) {
    return this.masterDataService.getServiceTypes(includeInactive === 'true');
  }

  @Post('service-types')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create service type (Admin)' })
  async createServiceType(@Body() dto: CreateServiceTypeDto) {
    return this.masterDataService.createServiceType(dto);
  }

  @Put('service-types/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update service type (Admin)' })
  async updateServiceType(
    @Param('id') id: string,
    @Body() dto: UpdateServiceTypeDto,
  ) {
    return this.masterDataService.updateServiceType(id, dto);
  }

  @Delete('service-types/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete service type (Admin)' })
  async deleteServiceType(@Param('id') id: string) {
    return this.masterDataService.deleteServiceType(id);
  }

  @Get('provinces')
  @ApiOperation({ summary: 'Get all provinces (public)' })
  @ApiQuery({ name: 'includeInactive', required: false, type: Boolean })
  async getProvinces(@Query('includeInactive') includeInactive?: string) {
    return this.masterDataService.getProvinces(includeInactive === 'true');
  }

  @Get('provinces/:id')
  @ApiOperation({ summary: 'Get province by ID with districts' })
  async getProvinceById(@Param('id') id: string) {
    return this.masterDataService.getProvinceById(id);
  }

  @Get('districts')
  @ApiOperation({ summary: 'Get all districts (public)' })
  @ApiQuery({ name: 'provinceId', required: false })
  @ApiQuery({ name: 'includeInactive', required: false, type: Boolean })
  async getDistricts(
    @Query('provinceId') provinceId?: string,
    @Query('includeInactive') includeInactive?: string,
  ) {
    return this.masterDataService.getDistricts(provinceId, includeInactive === 'true');
  }

  @Get('provinces/:provinceId/districts')
  @ApiOperation({ summary: 'Get districts by province ID' })
  async getDistrictsByProvince(@Param('provinceId') provinceId: string) {
    return this.masterDataService.getDistrictsByProvince(provinceId);
  }

  @Get('interests')
  @ApiOperation({ summary: 'Get all interests (public)' })
  @ApiQuery({ name: 'categoryId', required: false })
  @ApiQuery({ name: 'includeInactive', required: false, type: Boolean })
  async getInterests(
    @Query('categoryId') categoryId?: string,
    @Query('includeInactive') includeInactive?: string,
  ) {
    return this.masterDataService.getInterests(categoryId, includeInactive === 'true');
  }

  @Get('interest-categories')
  @ApiOperation({ summary: 'Get all interest categories with interests' })
  @ApiQuery({ name: 'includeInactive', required: false, type: Boolean })
  async getInterestCategories(@Query('includeInactive') includeInactive?: string) {
    return this.masterDataService.getInterestCategories(includeInactive === 'true');
  }

  @Get('talents')
  @ApiOperation({ summary: 'Get all talents (public)' })
  @ApiQuery({ name: 'categoryId', required: false })
  @ApiQuery({ name: 'includeInactive', required: false, type: Boolean })
  async getTalents(
    @Query('categoryId') categoryId?: string,
    @Query('includeInactive') includeInactive?: string,
  ) {
    return this.masterDataService.getTalents(categoryId, includeInactive === 'true');
  }

  @Get('talent-categories')
  @ApiOperation({ summary: 'Get all talent categories with talents' })
  @ApiQuery({ name: 'includeInactive', required: false, type: Boolean })
  async getTalentCategories(@Query('includeInactive') includeInactive?: string) {
    return this.masterDataService.getTalentCategories(includeInactive === 'true');
  }

  @Get('languages')
  @ApiOperation({ summary: 'Get all languages (public)' })
  @ApiQuery({ name: 'includeInactive', required: false, type: Boolean })
  async getLanguages(@Query('includeInactive') includeInactive?: string) {
    return this.masterDataService.getLanguages(includeInactive === 'true');
  }

  // ==================== Admin Endpoints ====================

  @Post('provinces')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create province (Admin)' })
  async createProvince(@Body() dto: CreateProvinceDto) {
    return this.masterDataService.createProvince(dto);
  }

  @Put('provinces/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update province (Admin)' })
  async updateProvince(@Param('id') id: string, @Body() dto: UpdateProvinceDto) {
    return this.masterDataService.updateProvince(id, dto);
  }

  @Delete('provinces/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete province (Admin)' })
  async deleteProvince(@Param('id') id: string) {
    return this.masterDataService.deleteProvince(id);
  }

  @Post('districts')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create district (Admin)' })
  async createDistrict(@Body() dto: CreateDistrictDto) {
    return this.masterDataService.createDistrict(dto);
  }

  @Put('districts/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update district (Admin)' })
  async updateDistrict(@Param('id') id: string, @Body() dto: UpdateDistrictDto) {
    return this.masterDataService.updateDistrict(id, dto);
  }

  @Delete('districts/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete district (Admin)' })
  async deleteDistrict(@Param('id') id: string) {
    return this.masterDataService.deleteDistrict(id);
  }

  @Post('interest-categories')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create interest category (Admin)' })
  async createInterestCategory(@Body() dto: CreateInterestCategoryDto) {
    return this.masterDataService.createInterestCategory(dto);
  }

  @Post('interests')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create interest (Admin)' })
  async createInterest(@Body() dto: CreateInterestDto) {
    return this.masterDataService.createInterest(dto);
  }

  @Put('interests/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update interest (Admin)' })
  async updateInterest(@Param('id') id: string, @Body() dto: UpdateInterestDto) {
    return this.masterDataService.updateInterest(id, dto);
  }

  @Delete('interests/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete interest (Admin)' })
  async deleteInterest(@Param('id') id: string) {
    return this.masterDataService.deleteInterest(id);
  }

  @Post('talent-categories')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create talent category (Admin)' })
  async createTalentCategory(@Body() dto: CreateTalentCategoryDto) {
    return this.masterDataService.createTalentCategory(dto);
  }

  @Post('talents')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create talent (Admin)' })
  async createTalent(@Body() dto: CreateTalentDto) {
    return this.masterDataService.createTalent(dto);
  }

  @Put('talents/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update talent (Admin)' })
  async updateTalent(@Param('id') id: string, @Body() dto: UpdateTalentDto) {
    return this.masterDataService.updateTalent(id, dto);
  }

  @Delete('talents/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete talent (Admin)' })
  async deleteTalent(@Param('id') id: string) {
    return this.masterDataService.deleteTalent(id);
  }

  @Post('languages')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create language (Admin)' })
  async createLanguage(@Body() dto: CreateLanguageDto) {
    return this.masterDataService.createLanguage(dto);
  }

  @Put('languages/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update language (Admin)' })
  async updateLanguage(@Param('id') id: string, @Body() dto: UpdateLanguageDto) {
    return this.masterDataService.updateLanguage(id, dto);
  }

  @Delete('languages/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete language (Admin)' })
  async deleteLanguage(@Param('id') id: string) {
    return this.masterDataService.deleteLanguage(id);
  }
}
