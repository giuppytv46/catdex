import { access, readFile } from 'node:fs/promises';
import path from 'node:path';
import type { CardTemplateLayout, CatRarity, SelectedTemplate } from './types';

const templatesRoot = path.join(process.cwd(), 'assets/cards/templates');

async function exists(filePath: string): Promise<boolean> {
  try {
    await access(filePath);
    return true;
  } catch {
    return false;
  }
}

function templatePaths(templateKey: string) {
  const templateDirectory = path.join(templatesRoot, templateKey);
  return {
    templatePath: path.join(templateDirectory, 'template.png'),
    layoutPath: path.join(templateDirectory, 'layout.json'),
  };
}

export async function selectTemplate(rarity: CatRarity, eventKey?: string): Promise<SelectedTemplate> {
  const eventTemplateKey = eventKey ? `events/${eventKey}/${rarity}` : undefined;

  if (eventTemplateKey) {
    const eventPaths = templatePaths(eventTemplateKey);
    if (await exists(eventPaths.templatePath) && (await exists(eventPaths.layoutPath))) {
      return loadSelectedTemplate(eventTemplateKey, eventPaths.templatePath, eventPaths.layoutPath);
    }
  }

  const defaultTemplateKey = `default/${rarity}`;
  const defaultPaths = templatePaths(defaultTemplateKey);
  if (await exists(defaultPaths.templatePath) && (await exists(defaultPaths.layoutPath))) {
    return loadSelectedTemplate(defaultTemplateKey, defaultPaths.templatePath, defaultPaths.layoutPath);
  }

  const commonTemplateKey = 'default/common';
  const commonPaths = templatePaths(commonTemplateKey);
  return loadSelectedTemplate(commonTemplateKey, commonPaths.templatePath, commonPaths.layoutPath);
}

async function loadSelectedTemplate(key: string, templatePath: string, layoutPath: string): Promise<SelectedTemplate> {
  const layout = JSON.parse(await readFile(layoutPath, 'utf8')) as CardTemplateLayout;

  return {
    key,
    templatePath,
    layoutPath,
    layout,
  };
}
