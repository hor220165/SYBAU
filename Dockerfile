FROM node:22-alpine AS frontend
WORKDIR /frontend

COPY sybau_frontend/package*.json ./
RUN npm ci

COPY sybau_frontend/ ./
RUN npm run build

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /app

COPY Sybau_Backend/Sybau_Backend/*.csproj ./
RUN dotnet restore

COPY Sybau_Backend/Sybau_Backend/ ./
RUN dotnet publish -c Release -o out

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app/out ./
COPY --from=frontend /frontend/dist ./wwwroot
ENTRYPOINT ["dotnet", "Sybau_Backend.dll"]
